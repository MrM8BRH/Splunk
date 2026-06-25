#!/bin/bash
# ======================================================================================
# Splunk Enterprise — Production Installation Script
# Author  : @MrM8BRH
# Version : 1.1.3
#
# Supported topology : Fresh install, RPM-based Splunk Enterprise only.
#
# Requirements: bash 4.2+, RPM-based Linux (RHEL/Rocky/Alma/CentOS), x86_64
# Must be run as root.
# ======================================================================================

set -Eeuo pipefail

###############################################################################
# STATIC CONFIGURATION — edit these before deployment
###############################################################################

SPLUNK_HOME="/opt/splunk"
SPLUNK_USER="splunk"
SPLUNK_GROUP="splunk"
SPLUNK_PAGE="https://www.splunk.com/en_us/download/splunk-enterprise.html"

CONNECTIVITY_HOST="download.splunk.com"

# Readiness-wait timeout after start (seconds)
READY_TIMEOUT=120

# Minimum free space required (MB) — now a warning, not a hard limit
MIN_FREE_SPLUNK_MB=10240

# Minimum CPU cores and RAM (MB) — now warnings
MIN_CPU_CORES=12
MIN_RAM_MB=12288   # 12 GB

# Timestamped log directory — symlink "latest.log" maintained automatically.
LOG_DIR="/var/log/splunk-install"

# Execution lock — prevents concurrent runs.
LOCK_FILE="/var/lock/splunk-enterprise-install.lock"

# Service name (systemd)
SPLUNK_SERVICE="Splunkd.service"
SPLUNK_UNIT_FILE="/etc/systemd/system/${SPLUNK_SERVICE}"

###############################################################################
# RUNTIME STATE — do not edit
###############################################################################

EXEC_ID="$(date '+%Y%m%d%H%M%S')-$$"
HOSTNAME_SHORT="$(hostname -s 2>/dev/null || hostname)"
LOG_FILE=""
WORK_DIR=""
PACKAGE_PATH=""
SPLUNK_DOWNLOAD_URL=""
SPLUNK_BIN="${SPLUNK_HOME}/bin/splunk"
IS_INTERACTIVE=true

# Collected inputs
INPUT_HOSTNAME=""
INPUT_ADMIN_PASS=""
ENABLE_KERNEL_NET_TUNING=false

# Per-step status tracking
declare -A STEP_STATUS=()

# Colors — disabled for non-TTY
Color_Off="" LRED="" LGREEN="" LYELLOW="" LGRAY="" CYAN="" BLUE="" DIM=""

###############################################################################
# ROOT CHECK
###############################################################################

if [ "$(id -u)" != "0" ]; then
    printf '\033[01;31m  ✖  This script must be run as root.\033[0m\n' >&2
    exit 1
fi

###############################################################################
# COLOR INIT — disabled automatically for non-terminal stdout
###############################################################################

init_colors() {
    if [ -t 1 ] && [ -t 0 ]; then
        IS_INTERACTIVE=true
        Color_Off=$(printf '\033[0m')
        LRED=$(printf '\033[01;31m')
        LGREEN=$(printf '\033[01;32m')
        LYELLOW=$(printf '\033[01;33m')
        LGRAY=$(printf '\033[1;37m')
        CYAN=$(printf '\033[01;36m')
        BLUE=$(printf '\033[00;34m')
        DIM=$(printf '\033[2m')
    else
        IS_INTERACTIVE=false
    fi
}
init_colors

###############################################################################
# BOX DRAWING SYSTEM
###############################################################################

BOX_W=78
INNER=$(( BOX_W - 2 ))

_repeat() {
    local char="$1" count="$2" i result=""
    for (( i=0; i<count; i++ )); do result+="${char}"; done
    printf '%s' "${result}"
}

box_top()   { printf "${LGRAY}┌%s┐${Color_Off}\n" "$(_repeat '─' $INNER)"; }
box_mid()   { printf "${LGRAY}├%s┤${Color_Off}\n" "$(_repeat '─' $INNER)"; }
box_bot()   { printf "${LGRAY}└%s┘${Color_Off}\n" "$(_repeat '─' $INNER)"; }
box_empty() { printf "${LGRAY}│%${INNER}s│${Color_Off}\n" ""; }

box_title() {
    local text="$1" tlen=${#1}
    local lpad=$(( (INNER - tlen) / 2 ))
    local rpad=$(( INNER - tlen - lpad ))
    printf "${LGRAY}│${Color_Off}%${lpad}s${CYAN}%s${Color_Off}%${rpad}s${LGRAY}│${Color_Off}\n" \
        "" "${text}" ""
}

box_kv() {
    local key="$1" val="$2" vcol="${3:-${LGREEN}}"
    local vis=$(( 2 + 16 + 2 + ${#val} ))
    local pad=$(( INNER - vis - 1 ))
    [ $pad -lt 0 ] && pad=0
    printf "${LGRAY}│${Color_Off}  ${DIM}%-16s${Color_Off}  ${vcol}%s${Color_Off}%${pad}s ${LGRAY}│${Color_Off}\n" \
        "${key}" "${val}" ""
}

box_line() {
    local text="$1" indent="${2:-2}"
    local vis=$(( indent + ${#text} ))
    local pad=$(( INNER - vis - 1 ))
    [ $pad -lt 0 ] && pad=0
    printf "${LGRAY}│${Color_Off}%${indent}s%s%${pad}s ${LGRAY}│${Color_Off}\n" "" "${text}" ""
}

box_option() {
    local num="$1" label="$2" lcol="${3:-${Color_Off}}"
    local vis=$(( 2 + 3 + 2 + ${#label} ))
    local pad=$(( INNER - vis - 1 ))
    [ $pad -lt 0 ] && pad=0
    printf "${LGRAY}│${Color_Off}  ${LYELLOW}[%s]${Color_Off}  ${lcol}%s${Color_Off}%${pad}s ${LGRAY}│${Color_Off}\n" \
        "${num}" "${label}" ""
}

box_status() {
    local label="$1" status="$2"
    local icon col
    case "${status}" in
        PASS)           icon="✔" col="${LGREEN}"  ;;
        SKIPPED)        icon="─" col="${DIM}"     ;;
        WARNING)        icon="⚠" col="${LYELLOW}" ;;
        FAILED)         icon="✖" col="${LRED}"    ;;
        NOT_APPLICABLE) icon="·" col="${DIM}"     ;;
        NOT_RUN)        icon="·" col="${DIM}"     ;;
        *)              icon="?" col="${LGRAY}"   ;;
    esac
    local label_col=42
    local vis=$(( 4 + label_col + 2 + ${#status} ))
    local pad=$(( INNER - vis - 1 ))
    [ $pad -lt 0 ] && pad=0
    printf "${LGRAY}│${Color_Off}  ${col}%s${Color_Off}  %-*s  ${col}%s${Color_Off}%${pad}s ${LGRAY}│${Color_Off}\n" \
        "${icon}" "${label_col}" "${label}" "${status}" ""
}

log_section() {
    local label="  ${1}  " llen rlen
    llen=${#label}
    rlen=$(( INNER - llen - 1 ))
    [ $rlen -lt 0 ] && rlen=0
    echo ""
    printf "${LGRAY}┌─${LYELLOW}%s${LGRAY}%s┐${Color_Off}\n" "${label}" "$(_repeat '─' $rlen)"
    printf "${LGRAY}└%s┘${Color_Off}\n" "$(_repeat '─' $INNER)"
    echo ""
    _log_divider "${1}"
}

###############################################################################
# TERMINAL LOGGING HELPERS
###############################################################################

log_info()  { printf "${LGREEN}  ✔  %s${Color_Off}\n"  "$*"; }
log_warn()  { printf "${LYELLOW}  ⚠  %s${Color_Off}\n" "$*"; }
log_error() { printf "${LRED}  ✖  %s${Color_Off}\n"    "$*"; }
log_step()  { printf "${CYAN}  ➜  %s${Color_Off}\n"    "$*"; }

###############################################################################
# FILE LOGGING
###############################################################################

_log_raw()  { printf '%s\n' "$*" >> "${LOG_FILE}"; }

_log_divider() {
    {
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        printf "  [%s]  %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
    } >> "${LOG_FILE}"
}

log_to_file() {
    {
        echo "════════════════════════════════════════════════════════════════"
        printf "  TIMESTAMP : %s\n"  "$(date '+%Y-%m-%d %H:%M:%S')"
        printf "  EXEC_ID   : %s\n"  "${EXEC_ID}"
        printf "  SECTION   : %s\n"  "$1"
        printf "  COMMAND   : %s\n"  "$2"
        printf "  OUTPUT    :\n\n%s\n\n" "$3"
    } >> "${LOG_FILE}"
}

init_logging() {
    mkdir -p "${LOG_DIR}"
    chmod 750 "${LOG_DIR}"
    LOG_FILE="${LOG_DIR}/splunk-install-${HOSTNAME_SHORT}-${EXEC_ID}.log"
    touch "${LOG_FILE}"
    chmod 640 "${LOG_FILE}"
    ln -sfn "${LOG_FILE}" "${LOG_DIR}/latest.log"
    {
        echo "════════════════════════════════════════════════════════════════"
        echo "  Splunk Enterprise Installation Script v1.1.1"
        printf "  EXEC_ID    : %s\n" "${EXEC_ID}"
        printf "  HOST       : %s\n" "${HOSTNAME_SHORT}"
        printf "  DATE       : %s\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
        printf "  EUID       : %s\n" "$(id -u)"
        printf "  SPLUNK_HOME: %s\n" "${SPLUNK_HOME}"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
    } >> "${LOG_FILE}"
}

###############################################################################
# STEP STATUS TRACKING
###############################################################################

track_step() {
    local key="$1" status="$2" detail="${3:-}"
    STEP_STATUS["${key}"]="${status}"
    _log_raw "[STEP:${key}]  ${status}  ${detail}"
}

###############################################################################
# TRAP AND ABORT HANDLERS
###############################################################################

_abort() {
    local line="${1:-?}" func="${2:-?}"
    echo ""
    log_error "Unexpected failure in '${func}' at line ${line}."
    log_error "Installation did not complete. See: ${LOG_FILE}"
    printf "[ABORT]  %s  func=%s  line=%s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" "${func}" "${line}" >> "${LOG_FILE}"
    exit 1
}
trap '_abort "${LINENO}" "${FUNCNAME[0]:-main}"' ERR

_ctrl_c() {
    echo ""
    log_warn "Interrupted by user (CTRL+C)."
    _log_raw "[INTERRUPTED]  $(date '+%Y-%m-%d %H:%M:%S')"
    exit 130
}
trap '_ctrl_c' INT

_exit_cleanup() {
    local code=$?
    exec 9>&- 2>/dev/null || true
    if [ "${code}" -ne 0 ] && [ -d "${WORK_DIR:-}" ]; then
        log_warn "Working directory preserved for diagnostics: ${WORK_DIR}"
        _log_raw "[PRESERVED]  WORK_DIR=${WORK_DIR}  exit_code=${code}"
    elif [ "${code}" -eq 0 ] && [ -d "${WORK_DIR:-}" ]; then
        rm -rf "${WORK_DIR}" 2>/dev/null || true
    fi
}
trap '_exit_cleanup' EXIT

###############################################################################
# EXECUTION LOCK
###############################################################################

acquire_lock() {
    exec 9>"${LOCK_FILE}"
    if ! flock -n 9; then
        log_error "Another Splunk installation process is already running."
        log_error "Lock file: ${LOCK_FILE}"
        exit 1
    fi
    _log_raw "[LOCK]  acquired  pid=$$"
}

###############################################################################
# SECURE WORKING DIRECTORY
###############################################################################

init_environment() {
    umask 027
    WORK_DIR=$(mktemp -d -p /var/tmp "splunk-install.XXXXXX")
    chmod 700 "${WORK_DIR}"
    _log_raw "[ENV]  WORK_DIR=${WORK_DIR}"
}

###############################################################################
# HEADER
###############################################################################

print_header() {
    [ "${IS_INTERACTIVE}" = true ] && clear
    local W=88
    local line; line="$(_repeat '─' $W)"
    echo ""
    printf "${LGRAY}┌%s┐${Color_Off}\n" "${line}"
    printf "${LGRAY}│${Color_Off}%${W}s${LGRAY}│${Color_Off}\n" ""
    printf "${LGRAY}│${Color_Off}${LGREEN}    _____ ____  _     _   _ _   _ _  __                                                 ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}   / ____|  _ \\| |   | | | | \\ | | |/ /                                                 ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}  | (___ | |_) | |   | | | |  \\| | ' /                                                  ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}   \\___ \\|  __/| |   | | | | .   |  <                                                   ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}   ____) | |   | |___| |_| | |\\  | . \\                                                  ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}  |_____/|_|   |______\\___/|_| \\_|_|\\_\\                                                 ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}   _____           _        _ _       _   _                                             ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}  |_   _|         | |      | | |     | | (_)                                            ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}    | |  _ __  ___| |_ __ _| | | __ _| |_ _  ___  _ __                                  ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}    | | | '_ \\/ __| __/ _\` | | |/ _\` | __| |/ _ \\| '_ \\                                 ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}   _| |_| | | \\__ \\ || (_| | | | (_| | |_| | (_) | | | |                                ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}  |_____|_| |_|___/\\__\\__,_|_|_|\\__,_|\\__|_|\\___/|_| |_|                                ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}%${W}s${LGRAY}│${Color_Off}\n" ""
    printf "${LGRAY}├%s┤${Color_Off}\n" "${line}"

    local items=(
        "Splunk Enterprise  ·  Installation Script  ·  v1.1.1:${CYAN}"
        "Author => @MrM8BRH:${CYAN}"
        "RHEL / Rocky / Alma / CentOS  ·  x86_64 only:${DIM}"
    )
    for entry in "${items[@]}"; do
        local txt="${entry%%:*}" col="${entry##*:}"
        local lp=$(( (W - ${#txt}) / 2 ))
        local rp=$(( W - ${#txt} - lp ))
        printf "${LGRAY}│${Color_Off}%${lp}s${col}%s${Color_Off}%${rp}s${LGRAY}│${Color_Off}\n" \
            "" "${txt}" ""
    done

    printf "${LGRAY}│${Color_Off}%${W}s${LGRAY}│${Color_Off}\n" ""
    printf "${LGRAY}└%s┘${Color_Off}\n" "${line}"
    echo ""
    log_info "Log: ${LOG_FILE}"
    echo ""
}

###############################################################################
# PREFLIGHT — DEPENDENCY VALIDATION
###############################################################################

validate_dependencies() {
    log_section "PREFLIGHT  ·  Dependency Validation"

    local required=(
        curl wget rpm flock mktemp id df grep sed awk head tail
        hostnamectl systemctl dnf ping uname tee
    )
    local missing=()
    for cmd in "${required[@]}"; do
        command -v "${cmd}" &>/dev/null || missing+=("${cmd}")
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing[*]}"
        track_step "dependencies" "FAILED" "${missing[*]}"
        exit 1
    fi

    log_info "All required commands present."
    track_step "dependencies" "PASS"
}

###############################################################################
# PREFLIGHT — SYSTEM VALIDATION (OS, arch, disk now a warning)
###############################################################################

validate_system() {
    log_section "PREFLIGHT  ·  System Validation"

    # Architecture check
    local arch; arch=$(uname -m)
    if [ "${arch}" != "x86_64" ]; then
        log_error "Architecture '${arch}' is unsupported — this script installs x86_64 RPMs only."
        track_step "system" "FAILED" "arch=${arch}"
        exit 1
    fi

    # OS family check — must be RPM-based
    if [ ! -f /etc/os-release ]; then
        log_error "/etc/os-release not found — cannot determine OS family."
        track_step "system" "FAILED" "no os-release"
        exit 1
    fi

    local distro id_like distro_id
    distro=$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-${ID}}")
    distro_id=$(. /etc/os-release && printf '%s' "${ID:-unknown}")
    id_like=$(. /etc/os-release && printf '%s' "${ID_LIKE:-}")

    local is_rhel_family=false
    case "${distro_id}" in
        rhel|centos|rocky|almalinux|ol|fedora) is_rhel_family=true ;;
    esac
    [[ "${id_like}" =~ rhel|centos|fedora ]] && is_rhel_family=true

    if [ "${is_rhel_family}" = false ]; then
        log_error "Unsupported distribution: ${distro}"
        log_error "This script supports RHEL-family systems only (RHEL, Rocky, Alma, CentOS, OL)."
        track_step "system" "FAILED" "not rhel family"
        exit 1
    fi

    # Refuse if Splunk is already installed
    if rpm -q splunk &>/dev/null; then
        log_error "Splunk is already installed via RPM."
        log_error "This script is for fresh installations only. Use the upgrade script instead."
        track_step "system" "FAILED" "splunk already installed"
        exit 1
    fi

    if [ -d "${SPLUNK_HOME}" ]; then
        log_warn "Directory ${SPLUNK_HOME} already exists but no RPM record found."
        log_warn "A prior TAR-based or incomplete install may be present."
        log_error "Refusing to install over an existing directory without RPM record."
        track_step "system" "FAILED" "splunk_home exists no rpm"
        exit 1
    fi

    # Disk space check — now a WARNING instead of a hard failure
    local free_mb
    free_mb=$(df -BM /opt --output=avail 2>/dev/null | tail -1 | tr -d 'M' | tr -d ' ' || echo 0)
    if [ "${free_mb:-0}" -lt "${MIN_FREE_SPLUNK_MB}" ]; then
        log_warn "Insufficient free space on /opt — have ${free_mb} MB, recommended minimum ${MIN_FREE_SPLUNK_MB} MB."
        log_warn "This is a warning only; installation will proceed."
        track_step "system" "WARNING" "disk_space low"
    else
        log_info "Free space    : ${free_mb} MB on /opt  (min: ${MIN_FREE_SPLUNK_MB} MB)"
        track_step "system" "PASS"
    fi

    log_info "Architecture  : ${arch}"
    log_info "Distribution  : ${distro}"
    _log_raw "[SYS]  arch=${arch}  os=${distro}  free_mb=${free_mb}"
}

###############################################################################
# NEW PREFLIGHT — STATIC IP CHECK
###############################################################################

check_static_ip() {
    log_section "PREFLIGHT  ·  Network – Static IP"

    local default_iface
    default_iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
    if [ -z "${default_iface}" ]; then
        log_warn "Could not determine default network interface."
        track_step "static_ip" "WARNING" "no default iface"
        return
    fi

    local bootproto=""
    # Try NetworkManager first (RHEL8+)
    if command -v nmcli &>/dev/null; then
        bootproto=$(nmcli -t -f BOOTPROTO dev show "${default_iface}" 2>/dev/null | head -1 | cut -d: -f2 || true)
    fi
    # Fallback to ifcfg files
    if [ -z "${bootproto}" ] || [ "${bootproto}" = "unknown" ]; then
        local ifcfg="/etc/sysconfig/network-scripts/ifcfg-${default_iface}"
        if [ -f "${ifcfg}" ]; then
            bootproto=$(grep -E '^BOOTPROTO=' "${ifcfg}" | cut -d= -f2 | tr -d '"' || true)
        fi
    fi

    if [[ "${bootproto}" =~ ^(dhcp|dhcp6)$ ]]; then
        log_error "Default interface '${default_iface}' is configured with DHCP (BOOTPROTO=${bootproto})."
        log_error "A static IP address is strongly recommended for production Splunk servers."
        track_step "static_ip" "WARNING" "DHCP detected"
    else
        log_info "Default interface '${default_iface}' uses static configuration (BOOTPROTO=${bootproto:-static})."
        track_step "static_ip" "PASS"
    fi
}

###############################################################################
# NEW PREFLIGHT — NTP LOCAL SERVER CHECK (with || true to avoid set -e)
###############################################################################

check_ntp_local() {
    log_section "PREFLIGHT  ·  NTP – Local Server"

    local ntp_config=""
    local ntp_server_list=()
    # Check chrony first (preferred)
    if [ -f /etc/chrony.conf ]; then
        ntp_config="/etc/chrony.conf"
        ntp_server_list=( $(grep -E '^server\s+' /etc/chrony.conf | awk '{print $2}' || true) )
    elif [ -f /etc/ntp.conf ]; then
        ntp_config="/etc/ntp.conf"
        ntp_server_list=( $(grep -E '^server\s+' /etc/ntp.conf | awk '{print $2}' || true) )
    else
        log_warn "No NTP configuration file found (chrony.conf or ntp.conf)."
        log_info "ℹ️  INFO: NTP not configured. Consider setting up a local NTP server."
        track_step "ntp_local" "WARNING" "no NTP config"
        return
    fi

    if [ ${#ntp_server_list[@]} -eq 0 ]; then
        log_warn "No 'server' entries found in ${ntp_config}."
        log_info "ℹ️  INFO: No NTP servers defined. Configure a local NTP server for time sync."
        track_step "ntp_local" "WARNING" "no servers defined"
        return
    fi

    # Check if any server is in private IP ranges (RFC 1918)
    local has_local=false
    for server in "${ntp_server_list[@]}"; do
        # Remove port if present
        server=${server%%:*}
        # Check if it's a private IP
        if [[ "${server}" =~ ^10\. ]] || \
           [[ "${server}" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || \
           [[ "${server}" =~ ^192\.168\. ]]; then
            has_local=true
            break
        fi
    done

    if [ "${has_local}" = true ]; then
        log_info "Found local (private) NTP server(s): ${ntp_server_list[*]}"
        track_step "ntp_local" "PASS"
    else
        log_warn "No local (private) NTP server found. Current servers: ${ntp_server_list[*]}"
        log_info "ℹ️  INFO: Consider using a local NTP server for accurate time sync."
        track_step "ntp_local" "WARNING" "no local NTP"
    fi
}

###############################################################################
# NEW PREFLIGHT — CPU AND RAM CHECK (now a warning)
###############################################################################

check_cpu_ram() {
    log_section "PREFLIGHT  ·  Hardware Resources"

    local cpu_cores
    cpu_cores=$(nproc 2>/dev/null || echo 0)
    local ram_mb
    ram_mb=$(free -m | awk '/^Mem:/ {print $2}' 2>/dev/null || echo 0)

    local warn=false
    if [ "${cpu_cores}" -lt "${MIN_CPU_CORES}" ]; then
        log_warn "CPU cores: ${cpu_cores} (recommended minimum: ${MIN_CPU_CORES})"
        warn=true
    else
        log_info "CPU cores : ${cpu_cores} (≥ ${MIN_CPU_CORES})"
    fi
    if [ "${ram_mb}" -lt "${MIN_RAM_MB}" ]; then
        log_warn "RAM: ${ram_mb} MB (recommended minimum: ${MIN_RAM_MB} MB / 12 GB)"
        warn=true
    else
        log_info "RAM       : ${ram_mb} MB (≥ ${MIN_RAM_MB} MB)"
    fi

    if [ "${warn}" = true ]; then
        log_warn "Hardware resources are below recommended minimums. Installation will continue."
        track_step "cpu_ram" "WARNING" "below recommended"
    else
        track_step "cpu_ram" "PASS"
    fi
}

###############################################################################
# STEP 1 — CHECK INTERNET ACCESS
###############################################################################

step_check_internet() {
    log_section "STEP 1  ·  Internet Connectivity Check"

    log_step "Checking connectivity to ${CONNECTIVITY_HOST} ..."

    local ping_ok=false curl_ok=false
    set +e
    ping -c 2 -W 5 "${CONNECTIVITY_HOST}" &>/dev/null && ping_ok=true
    curl -s --max-time 10 --head "https://${CONNECTIVITY_HOST}" -o /dev/null && curl_ok=true
    set -e

    if [ "${ping_ok}" = true ]; then
        log_info "ping to ${CONNECTIVITY_HOST}  ✔"
    else
        log_warn "ping to ${CONNECTIVITY_HOST} failed — ICMP may be blocked."
    fi

    if [ "${curl_ok}" = true ]; then
        log_info "HTTPS to ${CONNECTIVITY_HOST}  ✔"
    else
        log_error "HTTPS connectivity to ${CONNECTIVITY_HOST} failed."
        log_error "Ensure outbound HTTPS (443) is allowed for download.splunk.com"
        track_step "internet" "FAILED"; exit 1
    fi

    _log_raw "[INTERNET]  ping=${ping_ok}  https=${curl_ok}"
    track_step "internet" "PASS"
}

###############################################################################
# STEP 2 — SYSTEM UPDATE & REQUIRED PACKAGES
###############################################################################

step_update_system() {
    log_section "STEP 2  ·  System Update & Required Packages"

    log_step "Running dnf update -y ..."
    local out
    out=$(dnf update -y 2>&1)
    log_to_file "dnf_update" "dnf update -y" "${out}"
    log_info "System updated."

    log_step "Installing EPEL release ..."
    out=$(dnf install -y epel-release 2>&1 || true)
    log_to_file "epel" "dnf install -y epel-release" "${out}"
    log_info "EPEL release installed (or already present)."

    # Enable CRB repository
    log_step "Enabling CRB repository ..."
    if command -v crb &>/dev/null; then
        crb enable 2>&1 | tee -a "${LOG_FILE}" || true
    elif dnf config-manager --help &>/dev/null; then
        dnf config-manager --set-enabled crb 2>&1 | tee -a "${LOG_FILE}" || true
    else
        log_warn "CRB not enabled automatically; please run manually: dnf install -y dnf-utils && dnf config-manager --set-enabled crb"
    fi

    log_step "Installing core utilities ..."
    local core_pkgs=(
        net-tools nano bind-utils chkconfig wget net-tools tcpdump
        fio bzip2 sysstat elfutils polkit.x86_64 cloud-utils-growpart
        coreutils findutils procps shadow-utils
        chrony
    )
    out=$(dnf install -y "${core_pkgs[@]}" 2>&1)
    log_to_file "core_packages" "dnf install core" "${out}"
    log_info "Core utilities installed."

    log_step "Installing Splunk dependency libraries ..."
    local splunk_deps=(
        postgresql-libs openldap openldap-compat net-snmp-libs
        libxml2 libxslt xmlsec1 jemalloc mongo-c-driver
    )
    out=$(dnf install -y "${splunk_deps[@]}" 2>&1)
    log_to_file "splunk_deps" "dnf install splunk deps" "${out}"
    log_info "Splunk dependency libraries installed."

    _log_raw "[UPDATE]  system and packages installed successfully"
    track_step "system_update" "PASS"
}

###############################################################################
# STEP 3 — CHANGE HOSTNAME
###############################################################################

step_set_hostname() {
    log_section "STEP 3  ·  Hostname Configuration"

    local current_hostname
    current_hostname=$(hostname -f 2>/dev/null || hostname)
    log_info "Current hostname : ${current_hostname}"

    echo ""
    printf "${CYAN}  ➜  Enter the new hostname for this Splunk server${Color_Off}\n"
    printf "${DIM}     (leave blank to keep current: %s)${Color_Off}\n" "${current_hostname}"
    printf "${LGRAY}  ➤  ${Color_Off}"
    # -e enables proper backspace/line editing
    read -r -e INPUT_HOSTNAME

    if [ -z "${INPUT_HOSTNAME}" ]; then
        INPUT_HOSTNAME="${current_hostname}"
        log_warn "Hostname unchanged: ${INPUT_HOSTNAME}"
        track_step "hostname" "SKIPPED" "kept current"
        return
    fi

    log_step "Attempting to set hostname to: ${INPUT_HOSTNAME}"

    # Helper: add entry to /etc/hosts if missing
    add_hosts_entry() {
        if ! grep -q "${INPUT_HOSTNAME}" /etc/hosts 2>/dev/null; then
            echo "127.0.1.1 ${INPUT_HOSTNAME}" >> /etc/hosts 2>/dev/null || true
            log_info "Added ${INPUT_HOSTNAME} to /etc/hosts"
        fi
    }

    # Try 1: hostnamectl (proper method) – ignore errors
    hostnamectl set-hostname "${INPUT_HOSTNAME}" 2>/dev/null || true
    if [ "$(hostname -f 2>/dev/null || hostname)" = "${INPUT_HOSTNAME}" ]; then
        log_info "Hostname set via hostnamectl to: ${INPUT_HOSTNAME}"
        add_hosts_entry
        track_step "hostname" "PASS"
        _log_raw "[HOSTNAME]  set via hostnamectl  new=${INPUT_HOSTNAME}"
        return
    fi

    # Try 2: add /etc/hosts entry and retry hostnamectl
    add_hosts_entry
    hostnamectl set-hostname "${INPUT_HOSTNAME}" 2>/dev/null || true
    if [ "$(hostname -f 2>/dev/null || hostname)" = "${INPUT_HOSTNAME}" ]; then
        log_info "Hostname set via hostnamectl after adding /etc/hosts entry."
        track_step "hostname" "PASS"
        _log_raw "[HOSTNAME]  set via hostnamectl (after /etc/hosts)  new=${INPUT_HOSTNAME}"
        return
    fi

    # Try 3: fallback to hostname command + write /etc/hostname
    hostname "${INPUT_HOSTNAME}" 2>/dev/null || true
    echo "${INPUT_HOSTNAME}" > /etc/hostname 2>/dev/null || true
    if [ "$(hostname -f 2>/dev/null || hostname)" = "${INPUT_HOSTNAME}" ]; then
        log_warn "Hostname set temporarily via 'hostname' and /etc/hostname written."
        log_warn "It should survive reboot (if /etc/hostname is read)."
        log_warn "To be safe, after reboot run: hostnamectl set-hostname ${INPUT_HOSTNAME}"
        track_step "hostname" "WARNING" "temporary set"
        _log_raw "[HOSTNAME]  set via fallback  new=${INPUT_HOSTNAME}"
        return
    fi

    # If all attempts fail, just log and continue
    log_warn "Could not set hostname by any method. Continuing with current: $(hostname)"
    log_warn "You can set it later manually."
    track_step "hostname" "WARNING" "manual required"
    _log_raw "[HOSTNAME]  ALL FAILED  new=${INPUT_HOSTNAME}"
}

###############################################################################
# STEP 4 — DISABLE SELinux
###############################################################################

step_disable_selinux() {
    log_section "STEP 4  ·  SELinux Configuration"

    local current_status current_mode
    current_status=$(sestatus 2>/dev/null | grep "SELinux status" | awk '{print $3}' || echo "unknown")
    current_mode=$(sestatus 2>/dev/null | grep "Current mode" | awk '{print $3}' || echo "unknown")

    log_info "SELinux status : ${current_status}"
    log_info "Current mode   : ${current_mode}"
    _log_raw "[SELINUX]  status=${current_status}  mode=${current_mode}"

    if command -v setenforce &>/dev/null; then
        setenforce 0 2>/dev/null || true
        log_info "Runtime mode set to permissive (setenforce 0) – ignored if already disabled."
    fi

    local selinux_cfg="/etc/selinux/config"
    if [ -f "${selinux_cfg}" ] && [ -w "${selinux_cfg}" ]; then
        cp "${selinux_cfg}" "${selinux_cfg}.bak.${EXEC_ID}" || true
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' "${selinux_cfg}" || true
        log_info "SELinux=disabled written to ${selinux_cfg}"
        log_warn "A system reboot is required for the SELinux change to fully apply."
    else
        log_warn "${selinux_cfg} not writable or missing — skipping persistent SELinux configuration."
    fi

    track_step "selinux" "PASS"
}

###############################################################################
# STEP 5 — SET ULIMITS
###############################################################################

step_set_ulimits() {
    log_section "STEP 5  ·  System Limits (ulimits)"

    local limits_file="/etc/security/limits.d/99-splunk.conf"

    log_step "Writing ${limits_file} ..."

    cat > "${limits_file}" << 'EOF'
# Splunk Enterprise — system limits
# Generated by splunk_enterprise_install.sh

splunk  soft  nofile    65535
splunk  hard  nofile    65535

splunk  soft  nproc     65535
splunk  hard  nproc     65535

splunk  soft  data      20000000
splunk  hard  data      20000000

splunk  soft  fsize     -1
splunk  hard  fsize     -1
EOF

    chmod 644 "${limits_file}"
    log_info "Limits file written: ${limits_file}"
    log_to_file "ulimits" "cat ${limits_file}" "$(cat "${limits_file}")"
    track_step "ulimits" "PASS"
}

###############################################################################
# STEP 6 — DISABLE HOST-BASED FIREWALL
###############################################################################

step_disable_firewall() {
    log_section "STEP 6  ·  Host Firewall"

    local fw_status
    fw_status=$(systemctl is-active firewalld 2>/dev/null || echo "inactive")

    if [ "${fw_status}" = "inactive" ]; then
        log_info "firewalld is already inactive — nothing to do."
        track_step "firewall" "SKIPPED" "already inactive"
        return
    fi

    log_step "Stopping firewalld ..."
    systemctl stop firewalld
    log_step "Disabling firewalld ..."
    systemctl disable firewalld

    log_info "firewalld stopped and disabled."
    log_warn "Ensure perimeter/cloud security groups enforce host-level network policy."
    _log_raw "[FIREWALL]  stopped and disabled"
    track_step "firewall" "PASS"
}

###############################################################################
# STEP 7 — DISABLE TRANSPARENT HUGE PAGES (THP)
###############################################################################

step_disable_thp() {
    log_section "STEP 7  ·  Transparent Huge Pages (THP)"

    local thp_service="/etc/systemd/system/disable-thp.service"

    log_step "Writing ${thp_service} ..."

    cat > "${thp_service}" << 'EOF'
[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 "${thp_service}"
    log_step "Reloading systemd daemon ..."
    systemctl daemon-reload

    log_step "Starting disable-thp service ..."
    systemctl start disable-thp

    log_step "Enabling disable-thp service on boot ..."
    systemctl enable disable-thp

    local thp_val
    thp_val=$(cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null | grep -oP '\[.*?\]' | tr -d '[]' || echo "unknown")
    log_info "THP enabled value  : ${thp_val}"

    if [ "${thp_val}" = "never" ]; then
        log_info "THP successfully disabled."
    else
        log_warn "THP value is '${thp_val}' — expected 'never'. Review /sys/kernel/mm/transparent_hugepage/enabled."
    fi

    _log_raw "[THP]  service created and enabled  thp_val=${thp_val}"
    track_step "thp" "PASS"
}

###############################################################################
# STEP 8 — KERNEL NETWORK & MEMORY TUNING (Optional — Indexer)
###############################################################################

step_kernel_tuning() {
    log_section "STEP 8  ·  Kernel Network & Memory Tuning (Indexer — Optional)"

    echo ""
    box_top
    box_empty
    box_title "Kernel Network Optimization"
    box_mid
    box_empty
    box_line "This step applies sysctl tuning recommended for Splunk Indexers." 4
    box_empty
    box_line "Parameters to be applied:" 4
    box_line "  net.core.rmem_default = 67108864   (64 MB)" 4
    box_line "  net.core.rmem_max     = 134217728  (128 MB)" 4
    box_line "  net.core.netdev_max_backlog = 250000" 4
    box_empty
    box_bot
    echo ""

    printf "${CYAN}  ➜  Apply kernel network tuning? [y/N]: ${Color_Off}"
    read -r answer

    if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
        log_warn "Kernel tuning skipped — recommended for Indexer roles."
        track_step "kernel_tuning" "SKIPPED" "user opted out"
        return
    fi

    ENABLE_KERNEL_NET_TUNING=true

    local sysctl_conf="/etc/sysctl.d/99-splunk-network.conf"
    log_step "Writing ${sysctl_conf} ..."

    cat > "${sysctl_conf}" << 'EOF'
# Splunk Enterprise — Indexer network tuning
# Generated by splunk_enterprise_install.sh

# Receive socket buffer sizes
net.core.rmem_default = 67108864
net.core.rmem_max     = 134217728

# Network device backlog queue
net.core.netdev_max_backlog = 250000
EOF

    chmod 644 "${sysctl_conf}"

    log_step "Applying sysctl settings ..."
    local out
    out=$(/sbin/sysctl -p "${sysctl_conf}" 2>&1)
    log_to_file "sysctl" "/sbin/sysctl -p" "${out}"
    log_info "Kernel network tuning applied."
    _log_raw "[SYSCTL]  ${out}"
    track_step "kernel_tuning" "PASS"
}

###############################################################################
# REBOOT NOTICE
###############################################################################

print_reboot_notice() {
    echo ""
    box_top
    box_empty
    box_title "🔄 System Reboot Recommended"
    box_mid
    box_empty
    box_line "The following changes have been applied and will take full effect after a reboot:" 4
    box_line "  · SELinux set to disabled (persistent)" 4
    box_line "  · Transparent Huge Pages (THP) disabled" 4
    box_line "  · System limits (ulimits) for Splunk user" 4
    box_line "  · Kernel network tuning (if applied)" 4
    box_empty
    box_line "Splunk Enterprise is already installed and will start automatically on boot." 4
    box_empty
    box_bot
    echo ""

    printf "${LYELLOW}  ⚠  Reboot now? [y/N]: ${Color_Off}"
    read -r answer
    # Trim whitespace and convert to lowercase
    answer=$(echo "${answer}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if [[ "${answer}" =~ ^(y|yes)$ ]]; then
        log_info "System rebooting... Splunk will start after reboot."
        _log_raw "[REBOOT]  user requested reboot after installation"
        sync
        sleep 2
        reboot
    else
        log_warn "Reboot skipped. Remember to reboot later for all changes to take effect."
        _log_raw "[REBOOT]  skipped by user"
    fi
}

###############################################################################
# FIREWALL DOMAINS NOTICE
###############################################################################

print_firewall_domains() {
    echo ""
    box_top
    box_empty
    box_title "Sysadmin — Required DNS / Firewall Allowlist"
    box_mid
    box_empty
    box_line "Ensure the following domains are reachable from Splunk servers" 4
    box_line "over HTTPS (TCP 443) outbound:" 4
    box_empty
    box_line "  Splunk Portal & Licensing:" 4
    box_line "    https://www.splunk.com/" 6
    box_line "    https://login.splunk.com/" 6
    box_empty
    box_line "  Downloads & Apps:" 4
    box_line "    https://download.splunk.com" 6
    box_line "    https://splunkbase.splunk.com/" 6
    box_empty
    box_bot
    echo ""
    _log_raw "[DNS_NOTICE]  firewall domain allowlist printed"
}

###############################################################################
# STEP 9 — DOWNLOAD SPLUNK RPM
###############################################################################

step_download_splunk() {
    log_section "STEP 9  ·  Download Splunk Enterprise RPM"

    log_step "Fetching latest RPM URL from ${SPLUNK_PAGE} ..."

    set +e
    SPLUNK_DOWNLOAD_URL=$(curl -s --max-time 30 "${SPLUNK_PAGE}" | \
        grep -oP 'https://download\.splunk\.com/products/splunk/releases/[^"]+x86_64\.rpm' | \
        head -1)
    set -e

    if [ -z "${SPLUNK_DOWNLOAD_URL}" ]; then
        log_error "Could not scrape a valid RPM URL from ${SPLUNK_PAGE}."
        log_error "The page structure may have changed. Provide a direct URL manually."
        track_step "download" "FAILED" "url scrape failed"
        exit 1
    fi

    local rpm_filename; rpm_filename=$(basename "${SPLUNK_DOWNLOAD_URL}")
    PACKAGE_PATH="${WORK_DIR}/${rpm_filename}"

    log_info "URL  : ${SPLUNK_DOWNLOAD_URL}"
    log_info "File : ${PACKAGE_PATH}"
    _log_raw "[DOWNLOAD]  url=${SPLUNK_DOWNLOAD_URL}"

    log_step "Downloading ${rpm_filename} ..."
    wget -nv --show-progress --progress=bar:force --no-check-certificate \
        -O "${PACKAGE_PATH}" "${SPLUNK_DOWNLOAD_URL}" 2>&1 | tee -a "${LOG_FILE}"

    # checksum
    checksum_url="${SPLUNK_DOWNLOAD_URL}.sha256"
    checksum_file="${WORK_DIR}/$(basename "${checksum_url}")"
    log_step "Fetching checksum file from ${checksum_url} ..."

    if wget --no-check-certificate -q -O "${checksum_file}" "${checksum_url}" 2>/dev/null; then
        log_info "Checksum file downloaded: ${checksum_file}"
        computed_checksum=$(sha256sum "${PACKAGE_PATH}" | awk '{print $1}')
        expected_checksum=$(grep -oE '[a-fA-F0-9]{64}' "${checksum_file}" | head -1)
        if [ -z "${expected_checksum}" ]; then
            log_warn "No SHA256 hash found in checksum file. Skipping verification."
        elif [ "${computed_checksum}" = "${expected_checksum}" ]; then
            log_info "SHA256 checksum verification PASSED."
        else
            log_error "SHA256 checksum verification FAILED."
            log_error "Expected: ${expected_checksum}"
            log_error "Computed: ${computed_checksum}"
            track_step "download" "FAILED" "checksum mismatch"; exit 1
        fi
    else
        log_warn "Could not download .sha256 file. Trying .md5 ..."
        checksum_url="${SPLUNK_DOWNLOAD_URL}.md5"
        checksum_file="${WORK_DIR}/$(basename "${checksum_url}")"
        if wget --no-check-certificate -q -O "${checksum_file}" "${checksum_url}" 2>/dev/null; then
            log_info "MD5 checksum file downloaded: ${checksum_file}"
            computed_checksum=$(md5sum "${PACKAGE_PATH}" | awk '{print $1}')
            expected_checksum=$(grep -oE '[a-fA-F0-9]{32}' "${checksum_file}" | head -1)
            if [ -z "${expected_checksum}" ]; then
                log_warn "No MD5 hash found in checksum file. Skipping verification."
            elif [ "${computed_checksum}" = "${expected_checksum}" ]; then
                log_info "MD5 checksum verification PASSED."
            else
                log_error "MD5 checksum verification FAILED."
                log_error "Expected: ${expected_checksum}"
                log_error "Computed: ${computed_checksum}"
                track_step "download" "FAILED" "checksum mismatch"; exit 1
            fi
        else
            log_warn "Could not download checksum file (.sha256 or .md5). Skipping verification."
        fi
    fi

    if [ ! -f "${PACKAGE_PATH}" ] || [ ! -s "${PACKAGE_PATH}" ]; then
        log_error "Downloaded file is missing or empty: ${PACKAGE_PATH}"
        track_step "download" "FAILED" "file empty"
        exit 1
    fi

    log_info "Download complete: ${PACKAGE_PATH}"
    track_step "download" "PASS"
}


###############################################################################
# STEP 10 — INSTALL SPLUNK RPM
###############################################################################

step_install_rpm() {
    log_section "STEP 10  ·  RPM Installation"

    if [ ! -f "${PACKAGE_PATH}" ]; then
        log_error "RPM package not found: ${PACKAGE_PATH}"
        track_step "rpm_install" "FAILED" "package missing"; exit 1
    fi

    log_step "Installing ${PACKAGE_PATH} ..."
    local out
    out=$(rpm -ivh "${PACKAGE_PATH}" 2>&1)
    log_to_file "rpm_install" "rpm -ivh ${PACKAGE_PATH}" "${out}"
    log_info "${out}"

    if ! rpm -q splunk &>/dev/null; then
        log_error "RPM install appeared to succeed but 'splunk' package not found in RPM DB."
        track_step "rpm_install" "FAILED" "rpm db missing"; exit 1
    fi

    log_info "RPM installed successfully."

    log_step "Accepting license and verifying installed version ..."
    set +e
    local ver_out
    ver_out=$("${SPLUNK_BIN}" version --accept-license --no-prompt 2>&1)
    set -e
    log_info "${ver_out}"
    log_to_file "version_check" "splunk version" "${ver_out}"

    _log_raw "[RPM_INSTALL]  version=${ver_out}"
    track_step "rpm_install" "PASS"
}

###############################################################################
# STEP 11 — CREATE SPLUNK USER/GROUP & SET PERMISSIONS
###############################################################################

step_create_user() {
    log_section "STEP 11  ·  Splunk User, Group & Permissions"

    if ! getent group "${SPLUNK_GROUP}" &>/dev/null; then
        log_step "Creating group: ${SPLUNK_GROUP} ..."
        groupadd -r "${SPLUNK_GROUP}"
        log_info "Group '${SPLUNK_GROUP}' created."
    else
        log_info "Group '${SPLUNK_GROUP}' already exists."
    fi

    if ! getent passwd "${SPLUNK_USER}" &>/dev/null; then
        log_step "Creating user: ${SPLUNK_USER} ..."
        useradd -r -g "${SPLUNK_GROUP}" -d "${SPLUNK_HOME}" \
            -s /sbin/nologin -c "Splunk Enterprise" "${SPLUNK_USER}"
        log_info "User '${SPLUNK_USER}' created (system account, no login shell)."
    else
        log_info "User '${SPLUNK_USER}' already exists."
    fi

    log_step "Applying ownership and permissions to ${SPLUNK_HOME} ..."
    chown -R "${SPLUNK_USER}:${SPLUNK_GROUP}" "${SPLUNK_HOME}"
    chmod -R 755 "${SPLUNK_HOME}"
    log_info "Ownership set: ${SPLUNK_USER}:${SPLUNK_GROUP}"
    log_info "Permissions set: 755 on ${SPLUNK_HOME}"

    _log_raw "[USER]  user=${SPLUNK_USER}  group=${SPLUNK_GROUP}  home=${SPLUNK_HOME}"
    track_step "user_group" "PASS"
}

###############################################################################
# STEP 12 — FIX SPLUNK PERMISSIONS
###############################################################################

step_fix_permissions() {
    log_section "STEP 12  ·  Fix Splunk Permissions"

    log_step "Ensuring full ownership and permissions for ${SPLUNK_HOME}..."
    chown -R "${SPLUNK_USER}:${SPLUNK_GROUP}" "${SPLUNK_HOME}" 2>/dev/null || true
    chmod -R 755 "${SPLUNK_HOME}" 2>/dev/null || true

    # Ensure critical runtime directories exist and are writable
    mkdir -p "${SPLUNK_HOME}/var/run/splunk"
    mkdir -p "${SPLUNK_HOME}/var/log/splunk"
    mkdir -p "${SPLUNK_HOME}/var/lib/splunk"
    chown -R "${SPLUNK_USER}:${SPLUNK_GROUP}" "${SPLUNK_HOME}/var/run" "${SPLUNK_HOME}/var/log" "${SPLUNK_HOME}/var/lib" 2>/dev/null || true
    chmod 755 "${SPLUNK_HOME}/var/run" "${SPLUNK_HOME}/var/log" "${SPLUNK_HOME}/var/lib"
    chmod 755 "${SPLUNK_HOME}/var/run/splunk" "${SPLUNK_HOME}/var/log/splunk" "${SPLUNK_HOME}/var/lib/splunk"

    log_info "Permissions and directories fixed."
    track_step "fix_permissions" "PASS"
}

###############################################################################
# STEP 13 — CREATE SYSTEMD UNIT, VALIDATE, ENABLE (but do NOT start yet)
###############################################################################

step_enable_boot_start() {
    log_section "STEP 13  ·  Systemd Unit Creation (Official Method)"

    # Remove any existing unit to start fresh
    rm -f "${SPLUNK_UNIT_FILE}" 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true

    log_step "Cleaning up any previous Splunk boot-start configuration..."
    set +e
    "${SPLUNK_BIN}" disable boot-start 2>/dev/null
    set -e
    log_info "Previous boot-start configuration removed (if any)."

    log_step "Creating systemd unit using Splunk's official tool..."
    set +e
    "${SPLUNK_BIN}" enable boot-start \
        -systemd-managed 1 \
        -user "${SPLUNK_USER}" \
        -group "${SPLUNK_GROUP}" 2>&1 | tee -a "${LOG_FILE}"
    local enable_rc=$?
    set -e

    if [ ${enable_rc} -ne 0 ]; then
        log_error "Failed to enable boot-start. Exit code: ${enable_rc}"
        track_step "boot_start" "FAILED" "enable rc=${enable_rc}"; exit 1
    fi

    log_info "Boot-start enabled successfully."

    # --- Append additional limits to the unit file ---
    log_step "Appending recommended limits to ${SPLUNK_UNIT_FILE}..."
    if [ -f "${SPLUNK_UNIT_FILE}" ]; then
        if ! grep -q "LimitDATA=" "${SPLUNK_UNIT_FILE}"; then
            sed -i '/^\[Service\]/a LimitDATA=20000000000\nLimitFSIZE=infinity\nLimitNPROC=65536\nTasksMax=65536' "${SPLUNK_UNIT_FILE}"
            log_info "Limits appended."
        else
            log_info "Limits already present."
        fi
    else
        log_error "Unit file not found after enable boot-start: ${SPLUNK_UNIT_FILE}"
        track_step "boot_start" "FAILED" "unit missing"; exit 1
    fi

    # --- Validate the unit file ---
    log_step "Validating unit file with systemd-analyze verify..."
    set +e
    verify_out=$(systemd-analyze verify "${SPLUNK_UNIT_FILE}" 2>&1)
    verify_rc=$?
    set -e
    if [ ${verify_rc} -ne 0 ]; then
        log_error "systemd-analyze verify failed (rc=${verify_rc}):"
        log_error "${verify_out}"
        track_step "boot_start" "FAILED" "unit validation failed"; exit 1
    else
        log_info "Unit file validation passed."
        log_to_file "systemd_verify" "systemd-analyze verify" "${verify_out}"
    fi

    # --- Clean systemd environment ---
    log_step "Reloading systemd daemon and re-executing..."
    systemctl daemon-reload
    systemctl daemon-reexec 2>/dev/null || true

    log_step "Enabling ${SPLUNK_SERVICE} for boot..."
    systemctl enable "${SPLUNK_SERVICE}"

    log_info "Service unit created, validated, and enabled."
    _log_raw "[BOOTSTART]  unit created via official command"
    track_step "boot_start" "PASS"
}

###############################################################################
# STEP 14 — CONFIGURE WEB INTERFACE
###############################################################################

step_configure_web() {
    log_section "STEP 14  ·  Configure Web Interface"

    local web_conf="/opt/splunk/etc/system/local/web.conf"
    mkdir -p "$(dirname "${web_conf}")"

    log_step "Configuring Splunk Web UI to listen on all interfaces..."
    cat > "${web_conf}" << 'EOF'
[settings]
max_upload_size = 2048
enableSplunkWebSSL = true
splunkdConnectionTimeout = 600
EOF

    chown splunk:splunk "${web_conf}"
    chmod 644 "${web_conf}"
    log_info "Web interface configured to listen on (https://<IP_ADDRESS>:8000)."
    track_step "web_config" "PASS"
}

###############################################################################
# STEP 15 — FIRST START & ADMIN PASSWORD SETUP (using systemctl)
###############################################################################

step_start_splunk() {
    log_section "STEP 15  ·  First Start & Admin Setup"

    # Ensure runtime directories
    log_step "Ensuring runtime directories exist..."
    mkdir -p "${SPLUNK_HOME}/var/run/splunk" "${SPLUNK_HOME}/var/log/splunk" "${SPLUNK_HOME}/var/lib/splunk"
    chown -R "${SPLUNK_USER}:${SPLUNK_GROUP}" "${SPLUNK_HOME}/var/run" "${SPLUNK_HOME}/var/log" "${SPLUNK_HOME}/var/lib" 2>/dev/null || true
    chmod 755 "${SPLUNK_HOME}/var/run" "${SPLUNK_HOME}/var/log" "${SPLUNK_HOME}/var/lib"
    chmod 755 "${SPLUNK_HOME}/var/run/splunk" "${SPLUNK_HOME}/var/log/splunk" "${SPLUNK_HOME}/var/lib/splunk"

    # --- Clean up old credentials ---
    log_step "Cleaning up old credential files..."
    rm -f "${SPLUNK_HOME}/etc/system/local/user-seed.conf" 2>/dev/null || true
    rm -f "${SPLUNK_HOME}/etc/passwd" 2>/dev/null || true
    rm -f "${SPLUNK_HOME}/etc/auth/splunk.secret" 2>/dev/null || true

    # --- Create user-seed.conf with plaintext password (Splunk hashes it) ---
    log_step "Creating user-seed.conf with admin credentials..."
    local user_seed="${SPLUNK_HOME}/etc/system/local/user-seed.conf"
    mkdir -p "$(dirname "${user_seed}")"
    cat > "${user_seed}" << 'EOF'
[user_info]
USERNAME = admin
PASSWORD = Splunk@Cisco
EOF
    chmod 600 "${user_seed}"
    chown "${SPLUNK_USER}:${SPLUNK_GROUP}" "${user_seed}"
    log_info "user-seed.conf created with admin / Splunk@Cisco"

    # --- Stop any existing Splunk processes ---
    log_step "Stopping any existing Splunk processes..."
    systemctl stop "${SPLUNK_SERVICE}" 2>/dev/null || true
    "${SPLUNK_BIN}" stop --accept-license --no-prompt 2>/dev/null || true
    sleep 3
    rm -f /opt/splunk/var/run/splunk/*.pid 2>/dev/null || true
    systemctl reset-failed "${SPLUNK_SERVICE}" 2>/dev/null || true

    # Ensure port 8000 is free
    if ss -tulpn | grep -q ":8000 "; then
        log_warn "Port 8000 is still in use. Killing the process..."
        local pid=$(ss -tulpn | grep ":8000 " | awk '{print $7}' | cut -d'=' -f2 | cut -d',' -f1)
        [ -n "${pid}" ] && kill -9 ${pid} 2>/dev/null || true
        sleep 1
    fi

    # --- Start Splunk via systemctl (user-seed.conf will be consumed) ---
    log_step "Starting Splunk via systemctl ..."
    echo ""
    echo "======================================================================"
    echo "  Starting Splunk... user-seed.conf will create admin user."
    echo "  Default credentials: admin / Splunk@Cisco"
    echo "======================================================================"
    echo ""

    set +e
    systemctl start "${SPLUNK_SERVICE}" 2>&1 | tee -a "${LOG_FILE}"
    local start_rc=$?
    set -e

    if [ ${start_rc} -ne 0 ]; then
        log_error "systemctl start failed with exit code ${start_rc}."
        log_error "Checking systemd logs:"
        journalctl -u "${SPLUNK_SERVICE}" -n 50 --no-pager 2>&1 | tee -a "${LOG_FILE}"
        track_step "start" "FAILED" "systemctl start rc=${start_rc}"; exit 1
    fi

    # --- Wait for Splunk management port ---
    log_step "Waiting for Splunk management port (8089) to be ready..."
    local max_wait=180
    local waited=0
    local ready=false

    while [ "${waited}" -lt "${max_wait}" ]; do
        if ss -tulpn | grep -q ":8089 "; then
            ready=true
            break
        fi
        sleep 5
        waited=$(( waited + 5 ))
        printf "${DIM}     Waiting for port 8089 ... %ds${Color_Off}\r" "${waited}"
    done
    echo ""

    if [ "${ready}" = false ]; then
        log_error "Splunk management port did not become available within ${max_wait}s."
        if [ -f "${SPLUNK_HOME}/var/log/splunk/splunkd.log" ]; then
            tail -30 "${SPLUNK_HOME}/var/log/splunk/splunkd.log" | tee -a "${LOG_FILE}"
        else
            journalctl -u "${SPLUNK_SERVICE}" -n 50 --no-pager 2>&1 | tee -a "${LOG_FILE}"
        fi
        track_step "start" "FAILED" "port timeout"; exit 1
    fi

    log_info "Splunk management port is open."

    # --- Verify Splunk is fully ready ---
    log_step "Verifying Splunk is fully ready..."
    set +e
    "${SPLUNK_BIN}" status --accept-license --no-prompt &>/dev/null
    local status_rc=$?
    set -e
    if [ ${status_rc} -eq 0 ]; then
        log_info "Splunk status confirms readiness."
    else
        log_warn "splunk status returned non-zero, but port is open. Proceeding anyway."
    fi

    # --- user-seed.conf is automatically deleted by Splunk after consumption ---
    if [ ! -f "${user_seed}" ]; then
        log_info "user-seed.conf was consumed and removed by Splunk (expected behavior)."
    else
        log_warn "user-seed.conf still exists. It may not have been processed."
        rm -f "${user_seed}" 2>/dev/null || true
    fi

    log_info "Splunk is running and responsive under systemd."
    _log_raw "[START]  ready=true  waited=${waited}s"
    track_step "start" "PASS"
}

###############################################################################
# FINAL SUMMARY
###############################################################################

print_summary() {
    local all_pass=true
    for key in "${!STEP_STATUS[@]}"; do
        [ "${STEP_STATUS[$key]}" = "FAILED" ] && { all_pass=false; break; }
    done

    local ver_running
    set +e
    ver_running=$("${SPLUNK_BIN}" version --accept-license --no-prompt 2>/dev/null \
        | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
    set -e

    echo ""
    box_top
    box_empty

    if [ "${all_pass}" = true ]; then
        box_title "Splunk Enterprise Installation — Completed Successfully"
    else
        box_title "Splunk Enterprise Installation — Completed with Issues"
    fi

    box_empty
    box_mid
    box_empty

    local ordered_keys=(
        dependencies system static_ip ntp_local cpu_ram internet system_update
        hostname selinux ulimits firewall thp kernel_tuning download credentials
        rpm_install user_group boot_start start
    )
    local labels=(
        "Dependencies"           "System Validation"      "Static IP"
        "NTP Local Server"       "CPU / RAM"              "Internet Connectivity"
        "System Update"          "Hostname"               "SELinux"
        "Ulimits"                "Host Firewall"          "Transparent Huge Pages"
        "Kernel Tuning"          "RPM Download"           "Admin Credentials"
        "RPM Installation"       "User / Group"           "Boot-Start (systemd)"
        "First Start"
    )

    local i=0
    for key in "${ordered_keys[@]}"; do
        local status="${STEP_STATUS[$key]:-NOT_RUN}"
        box_status "${labels[$i]:-$key}" "${status}"
        i=$(( i + 1 ))
    done

    box_empty
    box_mid
    box_empty
    box_kv "Version"    "${ver_running:-unknown}" "${LGREEN}"
    box_kv "Home"       "${SPLUNK_HOME}"
    box_kv "User"       "${SPLUNK_USER}:${SPLUNK_GROUP}"
    box_kv "Hostname"   "${INPUT_HOSTNAME:-$(hostname)}"
    box_kv "Service"    "${SPLUNK_SERVICE}"
    box_empty
    box_mid
    box_empty

    local ip_addr
    ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown")
    local fqdn
    fqdn=$(hostname -f 2>/dev/null || hostname)

    if [ "${all_pass}" = true ]; then
        box_line "✔  Splunk Enterprise is installed and running." 4
        box_line "   Web UI  →  http://${fqdn}:8000" 4
        box_line "   or      →  http://${ip_addr}:8000" 4
    fi

    box_empty
    box_mid
    box_empty

    local ll="Log  : ${LOG_FILE}"
    local pad=$(( INNER - 2 - ${#ll} - 1 ))
    [ $pad -lt 0 ] && pad=0
    printf "${LGRAY}│${Color_Off}  ${DIM}%s${Color_Off}%${pad}s ${LGRAY}│${Color_Off}\n" "${ll}" ""

    local il="ID   : ${EXEC_ID}"
    pad=$(( INNER - 2 - ${#il} - 1 ))
    [ $pad -lt 0 ] && pad=0
    printf "${LGRAY}│${Color_Off}  ${DIM}%s${Color_Off}%${pad}s ${LGRAY}│${Color_Off}\n" "${il}" ""

    box_empty
    box_bot
    echo ""

    _log_raw "[SUMMARY]  exec_id=${EXEC_ID}  version=${ver_running:-unknown}  overall=$([ "${all_pass}" = true ] && echo PASS || echo ISSUES)"
}

###############################################################################
# MAIN
###############################################################################

main() {
    init_logging
    acquire_lock
    init_environment

    print_header

    # Phase 0 — Preflight
    validate_dependencies
    validate_system
    check_static_ip
    check_ntp_local
    check_cpu_ram

    # Phase 1 — System preparation
    step_check_internet
    step_update_system
    step_set_hostname
    step_disable_selinux
    step_set_ulimits
    step_disable_firewall
    step_disable_thp
    step_kernel_tuning          # optional — user prompted

    # Firewall domain notice for sysadmins
    print_firewall_domains

    # Phase 2 — Splunk installation
    step_download_splunk
    step_install_rpm
    step_create_user
    step_fix_permissions
    step_enable_boot_start
    step_configure_web
    step_start_splunk

    # Phase 3 — Report
    print_summary

    # Reboot prompt at the end
    print_reboot_notice
}

main "$@"
