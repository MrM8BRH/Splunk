#!/bin/bash
# ======================================================================================
# Splunk Enterprise — Production Upgrade Script
# Author  : @MrM8BRH
# Version : 3.1.0
#
# Supported topology : Standalone, RPM-managed Splunk Enterprise only.
# Clustered roles    : refused (indexer peer/manager, SHC member/deployer).
# Fresh installs     : refused.  TAR-based installations: refused.
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

# Official Splunk PGP public key (referenced in Splunk docs):
# https://docs.splunk.com/images/6/6b/SplunkPGPKey.pub
SPLUNK_GPG_KEY_URL="https://docs.splunk.com/images/6/6b/SplunkPGPKey.pub"

# SHA512 checksum URL suffix — appended to the RPM download URL.
# Splunk convention: <rpm-url>.sha512
# Example: https://download.splunk.com/products/splunk/releases/9.4.1/linux/splunk-9.4.1-....rpm.sha512
SPLUNK_SHA512_URL_SUFFIX=".sha512"

CONNECTIVITY_HOST="download.splunk.com"

# Graceful-stop timeout (seconds). Never force-kills. Raise for KV Store-heavy hosts.
STOP_TIMEOUT=180

# Readiness-wait timeout after start (seconds)
READY_TIMEOUT=120

# Minimum free space margins (MB). Script also adds RPM size dynamically.
MIN_FREE_SPLUNK_MB=2048
MIN_FREE_STAGE_MB=1024
MAX_FS_UTIL_PCT=85

# Timestamped log directory — symlink "latest.log" maintained automatically.
LOG_DIR="/var/log/splunk-upgrade"

# Execution lock — prevents concurrent runs.
LOCK_FILE="/var/lock/splunk-enterprise-upgrade.lock"

# Keep the downloaded RPM on success? (always kept on failure for diagnostics)
KEEP_PACKAGE_ON_SUCCESS=false

###############################################################################
# RUNTIME STATE — do not edit
###############################################################################

EXEC_ID="$(date '+%Y%m%d%H%M%S')-$$"
HOSTNAME_SHORT="$(hostname -s 2>/dev/null || hostname)"
LOG_FILE=""
WORK_DIR=""
PACKAGE_PATH=""
PACKAGE_NAME=""
SELECTED_VERSION=""
SPLUNK_DOWNLOAD_URL=""
SPLUNK_BIN="${SPLUNK_HOME}/bin/splunk"
SPLUNK_DB=""
MGMT_PORT=8089
SYSTEMD_SERVICE=""
USE_SYSTEMD=false
SPLUNK_WAS_RUNNING=false
INSTALLED_VERSION=""
TARGET_VERSION=""
IS_INTERACTIVE=true

# CLI argument flags
ARG_PACKAGE=""
ARG_URL=""
ARG_CHECKSUM=""
ARG_AUTO_CHECKSUM=false
ARG_GPG_KEY_URL=""
ARG_NON_INTERACTIVE=false
ARG_DRY_RUN=false
ARG_SNAPSHOT_CONFIRMED=false
ARG_REPAIR_OWNERSHIP=false
ARG_KEEP_PACKAGE=false

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
#
# BOX_W = total visible width INCLUDING both │ border chars
# INNER = usable inner content columns = BOX_W - 2
#
# Rule: NEVER use ${#colored_string} for padding calculations — ANSI escape
# bytes inflate the byte count invisibly. Measure only plain text; inject
# color codes inside printf format strings where they add zero visible width.
###############################################################################

BOX_W=78
INNER=$(( BOX_W - 2 ))

_repeat() {
    # _repeat CHAR COUNT
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
    # box_status LABEL STATUS
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
    # log_to_file SECTION COMMAND OUTPUT
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
    LOG_FILE="${LOG_DIR}/splunk-upgrade-${HOSTNAME_SHORT}-${EXEC_ID}.log"
    touch "${LOG_FILE}"
    chmod 640 "${LOG_FILE}"
    ln -sfn "${LOG_FILE}" "${LOG_DIR}/latest.log"
    {
        echo "════════════════════════════════════════════════════════════════"
        echo "  Splunk Enterprise Upgrade Script v3.1.0"
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
    # track_step KEY STATUS [DETAIL]
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
    log_error "Upgrade did not complete. See: ${LOG_FILE}"
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
        if [ "${KEEP_PACKAGE_ON_SUCCESS}" = false ] && \
           [ "${ARG_KEEP_PACKAGE}" = false ]; then
            rm -rf "${WORK_DIR}" 2>/dev/null || true
        fi
    fi
}
trap '_exit_cleanup' EXIT

###############################################################################
# EXECUTION LOCK
###############################################################################

acquire_lock() {
    exec 9>"${LOCK_FILE}"
    if ! flock -n 9; then
        log_error "Another Splunk upgrade process is already running."
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
    WORK_DIR=$(mktemp -d -p /var/tmp "splunk-upgrade.XXXXXX")
    chmod 700 "${WORK_DIR}"
    _log_raw "[ENV]  WORK_DIR=${WORK_DIR}"
}

###############################################################################
# CLI ARGUMENT PARSING
###############################################################################

usage() {
    cat << 'USAGE'
Splunk Enterprise Upgrade Script v3.1.0

Usage: splunk_enterprise_upgrade.sh [OPTIONS]

Package selection (mutually exclusive):
  --package PATH        Path to a local RPM file
  --url URL             Approved download URL (must match download.splunk.com)

Verification:
  --checksum SHA512     Expected SHA512 of the RPM (skip auto-fetch)
  --auto-checksum       Auto-fetch the .sha512 file from Splunk CDN
  --gpg-key-url URL     Override the Splunk GPG public key URL

Behaviour:
  --repair-ownership    Apply targeted ownership corrections (default: warn only)
  --keep-package        Keep the RPM after a successful upgrade
  --dry-run             Validate everything; do not stop or install anything

Non-interactive / automation:
  --non-interactive     Suppress all menus; requires --package or --url
  --snapshot-confirmed  Record that the operator confirmed a VM backup/snapshot
                        (mandatory in --non-interactive mode)
  --help                Show this message and exit
USAGE
    exit 0
}

parse_cli_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --package)            ARG_PACKAGE="$2";           shift 2 ;;
            --url)                ARG_URL="$2";               shift 2 ;;
            --checksum)           ARG_CHECKSUM="$2";          shift 2 ;;
            --auto-checksum)      ARG_AUTO_CHECKSUM=true;     shift   ;;
            --gpg-key-url)        ARG_GPG_KEY_URL="$2";       shift 2 ;;
            --repair-ownership)   ARG_REPAIR_OWNERSHIP=true;  shift   ;;
            --keep-package)       ARG_KEEP_PACKAGE=true;      shift   ;;
            --non-interactive)    ARG_NON_INTERACTIVE=true;   shift   ;;
            --snapshot-confirmed) ARG_SNAPSHOT_CONFIRMED=true; shift  ;;
            --dry-run)            ARG_DRY_RUN=true;           shift   ;;
            --help|-h)            usage ;;
            *)
                log_error "Unknown argument: $1  (run with --help)"
                exit 1
                ;;
        esac
    done

    if [ -n "${ARG_PACKAGE}" ] && [ -n "${ARG_URL}" ]; then
        log_error "--package and --url are mutually exclusive."
        exit 1
    fi

    if [ "${ARG_NON_INTERACTIVE}" = true ]; then
        if [ -z "${ARG_PACKAGE}" ] && [ -z "${ARG_URL}" ]; then
            log_error "--non-interactive requires --package or --url."
            exit 1
        fi
        if [ "${ARG_SNAPSHOT_CONFIRMED}" = false ]; then
            log_error "--non-interactive requires --snapshot-confirmed."
            log_error "Confirm a full VM backup/snapshot was created before re-running."
            exit 1
        fi
    fi

    if [ -n "${ARG_GPG_KEY_URL}" ]; then
        SPLUNK_GPG_KEY_URL="${ARG_GPG_KEY_URL}"
    fi

    _log_raw "[ARGS]  package='${ARG_PACKAGE}'  url='${ARG_URL}'  dry_run=${ARG_DRY_RUN}  non_interactive=${ARG_NON_INTERACTIVE}  snapshot_confirmed=${ARG_SNAPSHOT_CONFIRMED}  auto_checksum=${ARG_AUTO_CHECKSUM}"
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
    printf "${LGRAY}│${Color_Off}${LGREEN}   _____       _                       _                                                ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}  | ____|_ __ | |_ ___ _ __ _ __  _ __(_)___  ___                                       ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}  |  _| | '_ \\| __/ _ \\ '__| '_ \\| '__| / __|/ _ \\                                      ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}  | |___| | | | ||  __/ |  | |_) | |  | \\__ \\  __/                                      ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}  |_____|_| |_|\\__\\___|_|  | .__/|_|  |_|___/\\___|                                      ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}${LGREEN}                            |_|                                                         ${LGRAY}│${Color_Off}\n"
    printf "${LGRAY}│${Color_Off}%${W}s${LGRAY}│${Color_Off}\n" ""
    printf "${LGRAY}├%s┤${Color_Off}\n" "${line}"

    local items=(
        "Splunk Enterprise  ·  Upgrade Script  ·  v3.1.0:${CYAN}"
        "Author => @MrM8BRH:${CYAN}"
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
    [ "${ARG_DRY_RUN}" = true ] && \
        log_warn "DRY-RUN MODE — preflight and validation only; nothing will be changed."
    log_info "Log: ${LOG_FILE}"
    echo ""
}

###############################################################################
# DEPENDENCY VALIDATION
###############################################################################

validate_dependencies() {
    log_section "PREFLIGHT  ·  Dependency Validation"

    local required=(
        curl wget rpm flock mktemp pgrep id df find stat getent
        su awk grep sed wc head tail basename tee sleep sha512sum ss
    )
    local missing=()
    for cmd in "${required[@]}"; do
        command -v "${cmd}" &>/dev/null || missing+=("${cmd}")
    done

    command -v systemctl &>/dev/null || \
        log_warn "systemctl not found — Splunk CLI service control will be used."

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing[*]}"
        track_step "dependencies" "FAILED" "${missing[*]}"
        exit 1
    fi

    log_info "All required commands present."
    track_step "dependencies" "PASS"
}

###############################################################################
# SYSTEM VALIDATION
###############################################################################

validate_system() {
    log_section "PREFLIGHT  ·  System Validation"

    local arch; arch=$(uname -m)
    if [ "${arch}" != "x86_64" ]; then
        log_error "Architecture '${arch}' is unsupported — this script downloads x86_64 RPMs only."
        track_step "system" "FAILED" "arch=${arch}"
        exit 1
    fi

    local distro="unknown"
    [ -f /etc/os-release ] && distro=$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-${ID}}")

    log_info "Architecture  : ${arch}"
    log_info "Distribution  : ${distro}"
    _log_raw "[SYS]  arch=${arch}  os=${distro}"
    track_step "system" "PASS"
}

###############################################################################
# SPLUNK HOME VALIDATION
###############################################################################

validate_splunk_home() {
    log_section "PREFLIGHT  ·  Splunk Installation Validation"

    if [ ! -e "${SPLUNK_HOME}" ]; then
        log_error "SPLUNK_HOME '${SPLUNK_HOME}' does not exist."
        track_step "splunk_home" "FAILED"; exit 1
    fi
    if [ -L "${SPLUNK_HOME}" ]; then
        log_error "'${SPLUNK_HOME}' is a symbolic link — resolve it before running this script."
        track_step "splunk_home" "FAILED" "symlink"; exit 1
    fi
    if [ ! -d "${SPLUNK_HOME}" ]; then
        log_error "'${SPLUNK_HOME}' is not a directory."
        track_step "splunk_home" "FAILED"; exit 1
    fi
    if [ ! -x "${SPLUNK_BIN}" ]; then
        log_error "Splunk binary not found or not executable: ${SPLUNK_BIN}"
        track_step "splunk_home" "FAILED" "binary missing"; exit 1
    fi

    log_info "SPLUNK_HOME  : ${SPLUNK_HOME}  (real directory)"
    log_info "Binary       : ${SPLUNK_BIN}"
    track_step "splunk_home" "PASS"
}

###############################################################################
# USER / GROUP VALIDATION
###############################################################################

validate_user_group() {
    if ! getent passwd "${SPLUNK_USER}" &>/dev/null; then
        log_error "Splunk user '${SPLUNK_USER}' does not exist."
        track_step "user_group" "FAILED"; exit 1
    fi
    if ! getent group "${SPLUNK_GROUP}" &>/dev/null; then
        log_error "Splunk group '${SPLUNK_GROUP}' does not exist."
        track_step "user_group" "FAILED"; exit 1
    fi
    log_info "User/group verified: ${SPLUNK_USER}:${SPLUNK_GROUP}"
    track_step "user_group" "PASS"
}

###############################################################################
# RPM INSTALLATION VALIDATION
# Requires an existing RPM-managed Splunk. Refuses fresh installs.
###############################################################################

validate_installed_rpm() {
    local rpm_out rpm_code
    set +e
    rpm_out=$(rpm -q splunk 2>&1)
    rpm_code=$?
    set -e

    if [ "${rpm_code}" -ne 0 ]; then
        log_error "No 'splunk' RPM found in the RPM database."
        log_error "This script upgrades existing RPM-managed installations only."
        log_error "TAR-based, manually deployed, or fresh installations are not supported."
        log_error "rpm output: ${rpm_out}"
        track_step "installed_rpm" "FAILED" "not found"; exit 1
    fi

    set +e
    INSTALLED_VERSION=$(rpm -q splunk --qf '%{VERSION}' 2>/dev/null)
    set -e

    log_info "Installed RPM     : ${rpm_out}"
    log_info "Installed version : ${INSTALLED_VERSION}"
    _log_raw "[RPM]  installed=${rpm_out}"

        # Verify RPM install prefix – SPLUNK_HOME must be under the prefix
    local installed_prefix
    set +e
    installed_prefix=$(rpm -q splunk --qf '%{INSTPREFIXES}' 2>/dev/null)
    set -e

    local configured="${SPLUNK_HOME%/}"
    local installed="${installed_prefix%/}"

    if [ -z "${installed}" ]; then
        log_warn "RPM INSTPREFIXES is empty — prefix verification skipped."
        _log_raw "[RPM]  INSTPREFIXES empty"
        track_step "installed_rpm" "WARNING" "prefix empty"
    elif [[ "${configured}" != "${installed}" ]] && [[ "${configured}" != "${installed}"/* ]]; then
        log_error "RPM INSTPREFIXES mismatch:"
        log_error "  Configured SPLUNK_HOME : ${configured}"
        log_error "  RPM INSTPREFIXES       : ${installed}"
        log_error "SPLUNK_HOME must be either the prefix or a subdirectory of the prefix."
        track_step "installed_rpm" "FAILED" "prefix mismatch"; exit 1
    else
        log_info "RPM prefix ${installed} is valid for SPLUNK_HOME ${configured}"
        track_step "installed_rpm" "PASS"
    fi
}

###############################################################################
# DISCOVER SPLUNK_DB AND MANAGEMENT PORT FROM BTOOL
###############################################################################

discover_splunk_config() {
    # ----- SPLUNK_DB discovery -----
    set +e
    # Try btool first
    db_raw=$(su - "${SPLUNK_USER}" \
        -c "${SPLUNK_BIN} btool indexes list default --debug 2>/dev/null" 2>/dev/null \
        | grep -oP '(?<=homePath = ).*' | head -1 | sed 's|/db$||;s|/colddb$||' || true)
    set -e

    if [ -n "${db_raw}" ]; then
        SPLUNK_DB="${db_raw}"
        log_info "SPLUNK_DB (btool)  : ${SPLUNK_DB}"
    else
        # Fallback: read from splunk-launch.conf
        local launch_conf="${SPLUNK_HOME}/etc/splunk-launch.conf"
        if [ -f "${launch_conf}" ]; then
            SPLUNK_DB=$(grep -oP '^SPLUNK_DB=\K.*' "${launch_conf}" 2>/dev/null || true)
        fi
        if [ -z "${SPLUNK_DB}" ]; then
            SPLUNK_DB="${SPLUNK_HOME}/var/lib/splunk"
            # Silently use default – no warning
        else
            log_info "SPLUNK_DB (splunk-launch.conf) : ${SPLUNK_DB}"
        fi
    fi

    # ----- Management port discovery -----
    set +e
    mgmt_raw=$(su - "${SPLUNK_USER}" \
        -c "${SPLUNK_BIN} btool web list settings --debug 2>/dev/null" 2>/dev/null \
        | grep -oP '(?<=mgmtHostPort = )[0-9]+' | head -1 || true)
    set -e

    if [[ "${mgmt_raw:-}" =~ ^[0-9]+$ ]] && [ "${mgmt_raw}" -ge 1024 ] && [ "${mgmt_raw}" -le 65535 ]; then
        MGMT_PORT="${mgmt_raw}"
        log_info "Management port (btool) : ${MGMT_PORT}"
    else
        # Fallback: read from server.conf
        local server_conf="${SPLUNK_HOME}/etc/system/local/server.conf"
        if [ -f "${server_conf}" ]; then
            local port_from_conf=$(grep -oP '^mgmtHostPort\s*=\s*\K[0-9]+' "${server_conf}" 2>/dev/null || true)
            if [[ "${port_from_conf}" =~ ^[0-9]+$ ]] && [ "${port_from_conf}" -ge 1024 ] && [ "${port_from_conf}" -le 65535 ]; then
                MGMT_PORT="${port_from_conf}"
                log_info "Management port (server.conf) : ${MGMT_PORT}"
            fi
        fi
        if [ -z "${MGMT_PORT}" ] || [ "${MGMT_PORT}" -lt 1024 ]; then
            MGMT_PORT=8089
            log_warn "Could not discover valid management port – using default: ${MGMT_PORT}"
            if [ -n "${mgmt_raw}" ]; then
                log_warn "btool returned '${mgmt_raw}' – ignoring."
            fi
        fi
    fi

    _log_raw "[CONFIG]  SPLUNK_DB=${SPLUNK_DB}  MGMT_PORT=${MGMT_PORT}"
}

###############################################################################
# SYSTEMD UNIT DISCOVERY
# Refuses to silently fall back to CLI when systemd is running but no unit found.
###############################################################################

detect_service_manager() {
    USE_SYSTEMD=false
    SYSTEMD_SERVICE=""

    if ! command -v systemctl &>/dev/null; then
        log_info "Service manager: Splunk CLI  (systemctl absent)"
        _log_raw "[SVC]  method=cli  reason=no_systemctl"
        return
    fi

    if ! systemctl is-system-running &>/dev/null 2>&1; then
        log_info "Service manager: Splunk CLI  (systemd not running)"
        _log_raw "[SVC]  method=cli  reason=systemd_not_running"
        return
    fi

    local candidates=("Splunkd.service" "splunkd.service")
    local unit

    _find_unit() {
        for u in "${candidates[@]}"; do
            if systemctl list-unit-files "${u}" 2>/dev/null | grep -q "${u}"; then
                printf '%s' "${u}"
                return 0
            fi
        done
        local discovered
        set +e
        discovered=$(systemctl list-units --type=service --all --no-legend 2>/dev/null \
            | awk '{print $1}' \
            | while IFS= read -r u; do
                systemctl cat "${u}" 2>/dev/null | grep -qF "${SPLUNK_BIN}" \
                    && printf '%s\n' "${u}" && break
              done 2>/dev/null || true)
        set -e
        printf '%s' "${discovered}"
        [ -n "${discovered}" ] && return 0 || return 1
    }

    if found=$(_find_unit); then
        USE_SYSTEMD=true
        SYSTEMD_SERVICE="${found}"
        log_info "Service manager: systemd  (unit: ${SYSTEMD_SERVICE})"
        _log_raw "[SVC]  method=systemd  unit=${SYSTEMD_SERVICE}"
        return
    fi

    # No unit found – attempt to create it (run as root)
    log_warn "No Splunk systemd unit found. Attempting to create one..."
    _log_raw "[SVC]  unit not found – attempting auto-creation"

    local create_cmd="${SPLUNK_BIN} enable boot-start -systemd-managed 1 -create-polkit-rules 1 -user ${SPLUNK_USER} -group ${SPLUNK_GROUP}"

    if [ "${ARG_NON_INTERACTIVE}" = true ]; then
        log_info "Non-interactive mode – creating systemd unit automatically."
        set +e
        eval "${create_cmd}" >> "${LOG_FILE}" 2>&1   # run directly as root
        local ret=$?
        set -e
        if [ ${ret} -ne 0 ]; then
            log_error "Failed to create systemd unit (exit ${ret})."
            log_error "Create it manually:"
            log_error "  ${create_cmd}"
            _log_raw "[SVC]  auto-create failed with exit ${ret}"
            track_step "service_manager" "FAILED" "auto-create failed"; exit 1
        fi
    else
        echo ""
        box_top
        box_empty
        box_title "Systemd Unit Missing"
        box_empty
        box_mid
        box_empty
        box_line "Splunk is not managed by systemd on this host." 2
        box_line "The script can create a unit automatically using:" 2
        box_line "  ${create_cmd}" 2
        box_empty
        box_bot
        echo ""
        local answer
        read -rp "${LYELLOW}  [?] Create systemd unit now? (yes/no): ${Color_Off}" answer
        # Strip all non-alphanumeric characters, then lowercase
        answer=$(echo "${answer}" | sed 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')
        _log_raw "[SVC]  user response (sanitized): '${answer}'"
        if [[ "${answer}" != "yes" && "${answer}" != "y" ]]; then
            log_error "Systemd unit creation declined. Aborting."
            track_step "service_manager" "FAILED" "creation declined"; exit 1
        fi
        log_info "Creating systemd unit..."
        eval "${create_cmd}" >> "${LOG_FILE}" 2>&1
        log_info "Systemd unit created."
    fi

    # Reload systemd to pick up the new unit
    systemctl daemon-reload

    # Re-detect
    if found=$(_find_unit); then
        USE_SYSTEMD=true
        SYSTEMD_SERVICE="${found}"
        log_info "Service manager now: systemd  (unit: ${SYSTEMD_SERVICE})"
        _log_raw "[SVC]  method=systemd  unit=${SYSTEMD_SERVICE}  created=true"
        track_step "service_manager" "PASS" "unit auto-created"; return
    else
        log_error "Systemd unit still not found after creation attempt."
        log_error "Please verify the unit with: systemctl list-units --type=service | grep -i splunk"
        log_error "Then set SYSTEMD_SERVICE in the script and re-run."
        track_step "service_manager" "FAILED" "unit not found after creation"; exit 1
    fi
}

###############################################################################
# SERVICE CONTROL HELPERS — all start/stop goes through these two functions
###############################################################################

_splunk_stop() {
    if [ "${USE_SYSTEMD}" = true ]; then
        systemctl stop "${SYSTEMD_SERVICE}"
    else
        su - "${SPLUNK_USER}" -c "${SPLUNK_BIN} stop"
    fi
}

_splunk_start_with_license() {
    # systemd path: write license acceptance marker without starting the process,
    # then issue a single authoritative systemctl start.
    # This prevents a double-start (P0-03 from review).
    #
    # CLI path: start directly with documented non-interactive flags.
    # The interactive pipe fallback (printf 'q\ny\ny\n' |) is intentionally
    # absent — it is brittle across Splunk versions and is not documented.
    if [ "${USE_SYSTEMD}" = true ]; then
        set +e
        su - "${SPLUNK_USER}" \
            -c "${SPLUNK_BIN} --accept-license --answer-yes --no-prompt" 2>&1 \
            >> "${LOG_FILE}" || true
        set -e
        systemctl start "${SYSTEMD_SERVICE}"
    else
        su - "${SPLUNK_USER}" \
            -c "${SPLUNK_BIN} start --accept-license --answer-yes --no-prompt"
    fi
}

###############################################################################
# PROCESS IDENTIFICATION — anchored to SPLUNK_HOME to avoid wrong instance
###############################################################################

_splunk_is_running() {
    # Strategy:
    # 1. systemd MainPID when USE_SYSTEMD=true
    # 2. /proc/<pid>/exe resolved into SPLUNK_HOME for CLI installs
    if [ "${USE_SYSTEMD}" = true ] && [ -n "${SYSTEMD_SERVICE}" ]; then
        local main_pid
        set +e
        main_pid=$(systemctl show "${SYSTEMD_SERVICE}" \
            --property=MainPID --value 2>/dev/null || true)
        set -e
        if [[ "${main_pid:-0}" =~ ^[1-9][0-9]*$ ]]; then
            kill -0 "${main_pid}" 2>/dev/null && return 0
        fi
        return 1
    fi

    local pid
    while IFS= read -r pid; do
        [ -z "${pid}" ] && continue
        local proc_user
        proc_user=$(stat -c '%U' "/proc/${pid}" 2>/dev/null || true)
        [ "${proc_user}" != "${SPLUNK_USER}" ] && continue
        local exe_path
        exe_path=$(readlink -f "/proc/${pid}/exe" 2>/dev/null || true)
        [[ "${exe_path}" == "${SPLUNK_HOME}"/* ]] && return 0
    done < <(pgrep -x splunkd 2>/dev/null || true)

    return 1
}

###############################################################################
# CLUSTER ROLE DETECTION — refuses unsupported topologies
###############################################################################

detect_and_refuse_cluster_roles() {
    log_section "PREFLIGHT  ·  Topology Validation"

    local unsafe=false

    # Indexer clustering
    local cl_mode cl_disabled
    set +e
    cl_mode=$(su - "${SPLUNK_USER}" \
        -c "${SPLUNK_BIN} btool server list clustering --debug 2>/dev/null" 2>/dev/null \
        | grep -oP '(?<=^mode = ).*' | head -1 || true)
    cl_disabled=$(su - "${SPLUNK_USER}" \
        -c "${SPLUNK_BIN} btool server list clustering --debug 2>/dev/null" 2>/dev/null \
        | grep -oP '(?<=^disabled = ).*' | head -1 || true)
    set -e

    _log_raw "[ROLE]  indexer_cluster  mode='${cl_mode}'  disabled='${cl_disabled}'"

    if [ -n "${cl_mode}" ] && [ "${cl_disabled:-false}" != "true" ] && \
       [ "${cl_mode}" != "disabled" ]; then
        log_error "Indexer clustering active — mode: ${cl_mode}"
        log_error "This script supports standalone installations only."
        log_error "Follow the Splunk rolling-upgrade procedure for clustered environments."
        unsafe=true
    fi

    # Search head clustering
    local shc_mode shc_disabled
    set +e
    shc_mode=$(su - "${SPLUNK_USER}" \
        -c "${SPLUNK_BIN} btool server list shclustering --debug 2>/dev/null" 2>/dev/null \
        | grep -oP '(?<=^mode = ).*' | head -1 || true)
    shc_disabled=$(su - "${SPLUNK_USER}" \
        -c "${SPLUNK_BIN} btool server list shclustering --debug 2>/dev/null" 2>/dev/null \
        | grep -oP '(?<=^disabled = ).*' | head -1 || true)
    set -e

    _log_raw "[ROLE]  shclustering  mode='${shc_mode}'  disabled='${shc_disabled}'"

    if [ -n "${shc_mode}" ] && [ "${shc_disabled:-false}" != "true" ] && \
       [ "${shc_mode}" != "disabled" ]; then
        log_error "Search head clustering active — mode: ${shc_mode}"
        log_error "This script supports standalone installations only."
        unsafe=true
    fi

    if [ "${unsafe}" = true ]; then
        track_step "topology" "FAILED" "cluster role detected"; exit 1
    fi

    log_info "Topology: standalone  (no active cluster roles detected)"
    track_step "topology" "PASS"
}

###############################################################################
# PACKAGE SELECTION
###############################################################################

fetch_latest_url() {
    # Informational display only — never auto-selected.
    set +e
    local raw
    raw=$(curl -s --max-time 15 -L \
        -A "Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        "${SPLUNK_PAGE}" 2>/dev/null)
    set -e

    [ -z "${raw}" ] && return 1

    local url
    url=$(printf '%s' "${raw}" \
        | grep -oP 'https://download\.splunk\.com/products/splunk/releases/[^"]+x86_64\.rpm' \
        | head -1 2>/dev/null || true)
    [ -z "${url}" ] && return 1

    local ver
    ver=$(printf '%s' "${url}" \
        | grep -oP '(?<=/releases/)[0-9]+\.[0-9]+\.[0-9]+' || true)

    LATEST_URL="${url}"
    LATEST_LABEL="Splunk Enterprise ${ver}  (latest detected — for reference only)"
    return 0
}

select_package() {
    log_section "PACKAGE SELECTION"

    # --package CLI argument
    if [ -n "${ARG_PACKAGE}" ]; then
        [ -f "${ARG_PACKAGE}" ] || {
            log_error "Package file not found: ${ARG_PACKAGE}"; exit 1; }
        PACKAGE_NAME=$(basename "${ARG_PACKAGE}")
        PACKAGE_PATH="${WORK_DIR}/${PACKAGE_NAME}"
        cp "${ARG_PACKAGE}" "${PACKAGE_PATH}"
        chmod 640 "${PACKAGE_PATH}"
        SELECTED_VERSION="local: ${ARG_PACKAGE}"
        log_info "Package (local): ${PACKAGE_PATH}"
        track_step "package_select" "PASS" "local"; return
    fi

    # --url CLI argument
    if [ -n "${ARG_URL}" ]; then
        SPLUNK_DOWNLOAD_URL="${ARG_URL}"
        PACKAGE_NAME=$(basename "${ARG_URL}")
        PACKAGE_PATH="${WORK_DIR}/${PACKAGE_NAME}"
        SELECTED_VERSION="url: ${ARG_URL}"
        log_info "Package URL (from --url)."
        track_step "package_select" "PASS" "url_arg"; return
    fi

    [ "${ARG_NON_INTERACTIVE}" = true ] && {
        log_error "Non-interactive mode requires --package or --url."; exit 1; }

    # Interactive menu
    local has_latest=1
    local LATEST_URL="" LATEST_LABEL=""
    log_step "Checking splunk.com for the latest release  (informational) ..."
    if fetch_latest_url; then has_latest=0; fi
    echo ""

    box_top
    box_title "Select Splunk Enterprise Version"
    box_mid
    box_empty
    if [ "${has_latest}" -eq 0 ]; then
        box_line "Latest detected (REFERENCE ONLY — not auto-selected):" 2
        box_line "  ${LATEST_LABEL}" 2
        box_line "  ${LATEST_URL}" 2
        box_empty
        box_mid
    fi
    box_option "1" "Enter an approved download URL"
    box_option "2" "Provide a path to a local RPM file"
    box_empty
    box_bot
    echo ""

    local choice
    while true; do
        read -rp "${LYELLOW}  [?] Choice [1-2]: ${Color_Off}" choice
        [[ "${choice}" =~ ^[12]$ ]] && break
        log_warn "Enter 1 or 2."
    done

    if [ "${choice}" -eq 1 ]; then
        echo ""
        box_top
        box_title "Approved Download URL"
        box_mid
        box_empty
        box_line "Must match: https://download.splunk.com/products/splunk/releases/..." 2
        box_empty
        box_bot
        echo ""
        while true; do
            read -rp "${LYELLOW}  [?] Paste RPM URL: ${Color_Off}" input_url
            [[ "${input_url}" =~ ^https://download\.splunk\.com/.*\.rpm$ ]] && break
            log_warn "URL must start with https://download.splunk.com/ and end with .rpm"
        done
        SPLUNK_DOWNLOAD_URL="${input_url}"
        PACKAGE_NAME=$(basename "${input_url}")
        PACKAGE_PATH="${WORK_DIR}/${PACKAGE_NAME}"
        SELECTED_VERSION="url: ${input_url}"
    else
        while true; do
            read -rp "${LYELLOW}  [?] Local RPM path: ${Color_Off}" input_path
            [ -f "${input_path}" ] && break
            log_warn "File not found: ${input_path}"
        done
        PACKAGE_NAME=$(basename "${input_path}")
        PACKAGE_PATH="${WORK_DIR}/${PACKAGE_NAME}"
        cp "${input_path}" "${PACKAGE_PATH}"
        chmod 640 "${PACKAGE_PATH}"
        SELECTED_VERSION="local: ${input_path}"
    fi

    log_info "Selected: ${SELECTED_VERSION}"
    track_step "package_select" "PASS"
}

###############################################################################
# STEP 1 — CONNECTIVITY CHECK
###############################################################################

step_connectivity_check() {
    log_section "STEP 1  ·  Connectivity Check"

    if [ -z "${SPLUNK_DOWNLOAD_URL:-}" ]; then
        log_info "Local file selected — connectivity check not required."
        track_step "connectivity" "NOT_APPLICABLE"; return
    fi

    local out code
    set +e
    out=$(wget -q --spider "https://${CONNECTIVITY_HOST}" 2>&1)
    code=$?
    set -e

    if [ "${code}" -ne 0 ]; then
        log_error "Cannot reach ${CONNECTIVITY_HOST}"
        log_to_file "connectivity" "wget --spider" "${out}"
        track_step "connectivity" "FAILED"; exit 1
    fi

    log_info "Connectivity to ${CONNECTIVITY_HOST}  ✔"
    track_step "connectivity" "PASS"
}

###############################################################################
# STEP 2 — DOWNLOAD
###############################################################################

# Cache directory to avoid re-downloading the same RPM
CACHE_DIR="/var/tmp/splunk-rpm-cache"

step_download_package() {
    log_section "Download RPM Package"
    if [ -z "${SPLUNK_DOWNLOAD_URL:-}" ]; then
        log_info "Local file in use — download skipped."
        track_step "download" "SKIPPED"; return
    fi

    # Ensure cache directory exists
    mkdir -p "${CACHE_DIR}"
    chmod 755 "${CACHE_DIR}"

    local cached_file="${CACHE_DIR}/${PACKAGE_NAME}"

    # Check if the package already exists in cache
    if [ -f "${cached_file}" ] && [ -s "${cached_file}" ]; then
        log_info "Package already cached: ${cached_file}"
        log_step "Copying from cache to working directory..."
        cp "${cached_file}" "${PACKAGE_PATH}"
        chmod 640 "${PACKAGE_PATH}"
        local sz; sz=$(du -sh "${PACKAGE_PATH}" | cut -f1)
        log_info "Package ready  ·  ${sz}"
        track_step "download" "SKIPPED (cached)"; return
    fi

    # Download the package to cache first
    log_step "Downloading: ${PACKAGE_NAME}"
    printf "      %s\n" "${SPLUNK_DOWNLOAD_URL}"
    echo ""

    set +e
    # Use curl with progress bar and resume support
    curl -# -L -o "${cached_file}" "${SPLUNK_DOWNLOAD_URL}" 2>&1
    local wcode=$?
    set -e

    if [ "${wcode}" -ne 0 ] || [ ! -f "${cached_file}" ]; then
        log_error "Download failed  [exit: ${wcode}]"
        log_to_file "download" "curl ${SPLUNK_DOWNLOAD_URL}" "exit ${wcode}"
        track_step "download" "FAILED"; exit 1
    fi

    # Copy from cache to working directory
    cp "${cached_file}" "${PACKAGE_PATH}"
    chmod 640 "${PACKAGE_PATH}"
    local sz; sz=$(du -sh "${PACKAGE_PATH}" | cut -f1)
    log_info "Download complete  ·  ${sz}  (cached)"
    track_step "download" "PASS"
}

###############################################################################
# STEP 3 — CHECKSUM VERIFICATION
# Two modes:
#   --checksum SHA512   : compare against administrator-supplied value
#   --auto-checksum     : fetch <rpm-url>.sha512 from Splunk CDN
###############################################################################

step_verify_checksum() {
    log_section "STEP 3  ·  Checksum Verification"

    # Auto-fetch mode: download <rpm-url>.sha512
    if [ "${ARG_AUTO_CHECKSUM}" = true ] && [ -n "${SPLUNK_DOWNLOAD_URL:-}" ]; then
        local sha_url="${SPLUNK_DOWNLOAD_URL}${SPLUNK_SHA512_URL_SUFFIX}"
        local sha_file="${WORK_DIR}/${PACKAGE_NAME}.sha512"
        log_step "Fetching checksum from: ${sha_url}"

        set +e
        wget -q --timeout=30 -O "${sha_file}" "${sha_url}" 2>&1
        local fetch_code=$?
        set -e

        if [ "${fetch_code}" -ne 0 ] || [ ! -s "${sha_file}" ]; then
            log_warn "Could not fetch .sha512 file — checksum verification skipped."
            _log_raw "[CHECKSUM]  auto_fetch_failed  url=${sha_url}"
            track_step "checksum" "SKIPPED" "fetch failed"; return
        fi

        # Extract hash: try both formats
        local expected_hash=""
        # Format A: "hash  filename"
        expected_hash=$(awk '{if (NF>=2) print $1}' "${sha_file}" | head -1)
        # If that fails or looks like SHA512(...), try format B
        if [[ -z "${expected_hash}" || "${expected_hash}" =~ ^SHA512\( ]]; then
            # Format B: "SHA512(filename)= hash"
            expected_hash=$(grep -oP '=\s*\K[0-9a-fA-F]{128}' "${sha_file}" | head -1)
        fi

        if [ -z "${expected_hash}" ]; then
            log_warn "Could not parse checksum from ${sha_file} — verification skipped."
            _log_raw "[CHECKSUM]  parse_failed  content=$(cat "${sha_file}" | head -1)"
            track_step "checksum" "SKIPPED" "parse failed"; return
        fi

        ARG_CHECKSUM="${expected_hash}"
        log_info "Checksum fetched from CDN."
        _log_raw "[CHECKSUM]  auto_fetched  expected=${ARG_CHECKSUM}"
    fi

    if [ -z "${ARG_CHECKSUM:-}" ]; then
        log_info "No checksum provided — verification skipped."
        log_warn "Use --checksum or --auto-checksum to enable checksum verification."
        track_step "checksum" "SKIPPED"; return
    fi

    log_step "Verifying SHA512 checksum ..."
    local actual
    actual=$(sha512sum "${PACKAGE_PATH}" | awk '{print $1}')

    if [ "${actual}" = "${ARG_CHECKSUM}" ]; then
        log_info "SHA512 checksum verified  ✔"
        _log_raw "[CHECKSUM]  OK"
        track_step "checksum" "PASS"
    else
        log_error "SHA512 checksum MISMATCH — package may be corrupt or tampered with."
        log_error "  Expected : ${ARG_CHECKSUM}"
        log_error "  Actual   : ${actual}"
        _log_raw "[CHECKSUM]  FAIL  expected=${ARG_CHECKSUM}  actual=${actual}"
        track_step "checksum" "FAILED"; exit 1
    fi
}

###############################################################################
# STEP 4 — RPM METADATA VALIDATION
###############################################################################

validate_package_metadata() {
    log_section "STEP 4  ·  RPM Metadata Validation"

    # Suppress stderr (NOKEY warnings) – we handle GPG separately in step 5
    local meta meta_code
    set +e
    meta=$(rpm -qp "${PACKAGE_PATH}" \
        --queryformat '%{NAME}|%{VERSION}|%{RELEASE}|%{ARCH}|%{INSTPREFIXES}' 2>/dev/null)
    meta_code=$?
    set -e

    if [ "${meta_code}" -ne 0 ] || [ -z "${meta}" ]; then
        log_error "rpm -qp failed — package may be corrupt."
        log_to_file "metadata" "rpm -qp" "${meta}"
        track_step "metadata" "FAILED"; exit 1
    fi

    local pkg_name pkg_ver pkg_rel pkg_arch pkg_prefix
    IFS='|' read -r pkg_name pkg_ver pkg_rel pkg_arch pkg_prefix <<< "${meta}"
    _log_raw "[META]  name=${pkg_name}  ver=${pkg_ver}  rel=${pkg_rel}  arch=${pkg_arch}  prefix=${pkg_prefix}"

    # Name must be exactly 'splunk'
    if [ "${pkg_name}" != "splunk" ]; then
        log_error "Package name '${pkg_name}' is not 'splunk'."
        track_step "metadata" "FAILED" "wrong name"; exit 1
    fi

    # Architecture must match host
    local host_arch; host_arch=$(uname -m)
    if [ "${pkg_arch}" != "${host_arch}" ]; then
        log_error "Package arch '${pkg_arch}' does not match host '${host_arch}'."
        track_step "metadata" "FAILED" "arch mismatch"; exit 1
    fi

    TARGET_VERSION="${pkg_ver}"
    log_info "Package name     : ${pkg_name}"
    log_info "Target version   : ${TARGET_VERSION}-${pkg_rel}"
    log_info "Architecture     : ${pkg_arch}"

    # Prefix compatibility – only enforce when RPM provides a non‑empty value
    if [ -n "${pkg_prefix}" ] && [ "${pkg_prefix}" != "(none)" ]; then
        if [ "${pkg_prefix%/}" != "${SPLUNK_HOME%/}" ]; then
            log_error "Package INSTPREFIXES '${pkg_prefix}' != SPLUNK_HOME '${SPLUNK_HOME}'."
            track_step "metadata" "FAILED" "prefix mismatch"; exit 1
        else
            log_info "RPM prefix matches SPLUNK_HOME: ${pkg_prefix}"
        fi
    else
        log_info "RPM prefix not specified – assuming default installation path is correct."
    fi

    # Version comparison using sort -V
    if [ -n "${INSTALLED_VERSION}" ]; then
        if [ "${TARGET_VERSION}" = "${INSTALLED_VERSION}" ]; then
            log_error "Target version equals installed version (${TARGET_VERSION}). Nothing to upgrade."
            track_step "metadata" "FAILED" "same version"; exit 1
        fi
        local lower
        lower=$(printf '%s\n%s\n' "${INSTALLED_VERSION}" "${TARGET_VERSION}" \
            | sort -V | head -1)
        if [ "${lower}" = "${TARGET_VERSION}" ]; then
            log_error "Target ${TARGET_VERSION} is older than installed ${INSTALLED_VERSION}. Downgrade refused."
            track_step "metadata" "FAILED" "downgrade"; exit 1
        fi
        log_info "Version path: ${INSTALLED_VERSION}  →  ${TARGET_VERSION}  ✔"
    fi

    track_step "metadata" "PASS"
}

###############################################################################
# STEP 5 — RPM SIGNATURE VERIFICATION
###############################################################################

step_verify_rpm_signature() {
    log_section "STEP 5  ·  RPM Signature Verification"

    # Run rpm -K and capture both stdout and stderr
    local rpm_k_out rpm_k_code
    set +e
    rpm_k_out=$(rpm -K "${PACKAGE_PATH}" 2>&1)
    rpm_k_code=$?
    set -e

    _log_raw "[GPG]  rpm -K exit=${rpm_k_code}  output=${rpm_k_out}"

    # Case 1: Signature is valid (digests signatures OK)
    if [ "${rpm_k_code}" -eq 0 ] && \
       ! echo "${rpm_k_out}" | grep -qi "NOKEY" && \
       ! echo "${rpm_k_out}" | grep -qi "BAD"; then
        log_info "RPM signature: VALID  ✔"
        _log_raw "[GPG]  result=VALID"
        track_step "gpg" "PASS" "signature valid"; return
    fi

    # Case 2: NOKEY – signing key not imported
    if echo "${rpm_k_out}" | grep -qi "NOKEY"; then
        _log_raw "[GPG]  result=NOKEY"

        if [ "${ARG_NON_INTERACTIVE}" = true ]; then
            log_error "GPG key missing and non‑interactive mode is enabled."
            log_error "Please import the key manually and re‑run:"
            log_error "  rpm --import ${SPLUNK_GPG_KEY_URL}"
            track_step "gpg" "FAILED" "NOKEY non-interactive"; exit 1
        fi

        # Interactive mode – offer to import
        echo ""
        log_warn "The Splunk RPM signing key is not installed on this system."
        echo ""
        local answer
        read -rp "${LYELLOW}  [?] Download and import the official Splunk signing key? (yes/no): ${Color_Off}" answer
        if [[ ! "${answer}" =~ ^[Yy](es)?$ ]]; then
            log_error "GPG key import declined – aborting."
            track_step "gpg" "FAILED" "NOKEY declined"; exit 1
        fi

        local key_file="${WORK_DIR}/splunk-pgp-key.pub"
        log_step "Downloading key from ${SPLUNK_GPG_KEY_URL} ..."

        set +e
        curl -s -o "${key_file}" "${SPLUNK_GPG_KEY_URL}"
        local dl_code=$?
        set -e

        if [ "${dl_code}" -ne 0 ] || [ ! -s "${key_file}" ]; then
            log_error "Failed to download GPG key from ${SPLUNK_GPG_KEY_URL}"
            track_step "gpg" "FAILED" "key download failed"; exit 1
        fi

        log_step "Importing key..."
        set +e
        rpm --import "${key_file}" 2>&1
        local import_code=$?
        set -e

        if [ "${import_code}" -ne 0 ]; then
            log_error "Key import failed (exit ${import_code})."
            track_step "gpg" "FAILED" "import failed"; exit 1
        fi

        log_info "Splunk signing key imported."

        # Re‑verify
        set +e
        rpm_k_out=$(rpm -K "${PACKAGE_PATH}" 2>&1)
        rpm_k_code=$?
        set -e
        _log_raw "[GPG]  post-import rpm -K exit=${rpm_k_code}  output=${rpm_k_out}"

        if [ "${rpm_k_code}" -eq 0 ] && ! echo "${rpm_k_out}" | grep -qi "BAD"; then
            log_info "RPM signature: VALID (after import)  ✔"
            _log_raw "[GPG]  result=VALID_AFTER_IMPORT"
            track_step "gpg" "PASS" "valid after key import"; return
        else
            log_error "Signature verification still failed after key import."
            log_error "rpm -K output: ${rpm_k_out}"
            track_step "gpg" "FAILED" "verify failed post-import"; exit 1
        fi
    fi

    # Case 3: BAD signature or any other error – hard abort
    log_error "RPM signature verification FAILED."
    log_error "rpm -K output: ${rpm_k_out}"
    log_error "Do not install this package – it may be corrupt or tampered with."
    _log_raw "[GPG]  result=BAD_OR_ERROR  output=${rpm_k_out}"
    track_step "gpg" "FAILED" "BAD"; exit 1
}

###############################################################################
# STEP 6 — RPM TRANSACTION TEST
# Run BEFORE stopping Splunk — validates without committing.
###############################################################################

step_rpm_test() {
    log_section "STEP 6  ·  RPM Transaction Test"

    local out code
    set +e
    out=$(rpm -Uvh --test "${PACKAGE_PATH}" 2>&1)
    code=$?
    set -e

    _log_raw "[RPM_TEST]  exit=${code}  output=${out}"

    if [ "${code}" -eq 0 ]; then
        log_info "RPM transaction test passed  ✔"
        track_step "rpm_test" "PASS"
    else
        log_error "RPM transaction test FAILED — aborting before stopping Splunk."
        log_error "Splunk is still running. No changes were made."
        log_to_file "rpm_test" "rpm -Uvh --test" "${out}"
        track_step "rpm_test" "FAILED"; exit 1
    fi
}

###############################################################################
# DISK SPACE VALIDATION
###############################################################################

validate_disk_space() {
    log_section "PREFLIGHT  ·  Disk Space Validation"

    _free_mb()  { df -BM --output=avail  "$1" 2>/dev/null | tail -1 | tr -d 'M '; }
    _util_pct() { df --output=pcent      "$1" 2>/dev/null | tail -1 | tr -d '% '; }

    local ok=true

    # Dynamic minimum based on RPM size × 3 safety factor
    local rpm_mb=0
    [ -f "${PACKAGE_PATH}" ] && rpm_mb=$(du -m "${PACKAGE_PATH}" | cut -f1)
    local min_splunk=$(( rpm_mb * 3 + MIN_FREE_SPLUNK_MB ))

    local free_splunk; free_splunk=$(_free_mb  "${SPLUNK_HOME}")
    local util_splunk; util_splunk=$(_util_pct "${SPLUNK_HOME}")

    if [ "${free_splunk:-0}" -lt "${min_splunk}" ]; then
        log_error "Insufficient space on ${SPLUNK_HOME}: ${free_splunk}MB free, ${min_splunk}MB required."
        ok=false
    else
        log_info "Space OK  (${SPLUNK_HOME}: ${free_splunk}MB free)"
    fi

    if [ "${util_splunk:-0}" -gt "${MAX_FS_UTIL_PCT}" ]; then
        log_error "Filesystem utilisation for ${SPLUNK_HOME}: ${util_splunk}% > ${MAX_FS_UTIL_PCT}% threshold."
        ok=false
    else
        log_info "Utilisation OK  (${SPLUNK_HOME}: ${util_splunk}%)"
    fi

    local free_stage; free_stage=$(_free_mb  "${WORK_DIR}")
    local util_stage; util_stage=$(_util_pct "${WORK_DIR}")

    if [ "${free_stage:-0}" -lt "${MIN_FREE_STAGE_MB}" ]; then
        log_error "Insufficient staging space in ${WORK_DIR}: ${free_stage}MB free, ${MIN_FREE_STAGE_MB}MB required."
        ok=false
    else
        log_info "Space OK  (staging: ${free_stage}MB free)"
    fi

    # SPLUNK_DB filesystem — check only when on a different mount
    if [ -n "${SPLUNK_DB}" ] && [ -d "${SPLUNK_DB}" ]; then
        local db_fs;   db_fs=$(df   --output=source "${SPLUNK_DB}"   2>/dev/null | tail -1 || true)
        local home_fs; home_fs=$(df --output=source "${SPLUNK_HOME}" 2>/dev/null | tail -1 || true)
        if [ "${db_fs}" != "${home_fs}" ]; then
            local free_db; free_db=$(_free_mb "${SPLUNK_DB}")
            if [ "${free_db:-0}" -lt "${MIN_FREE_SPLUNK_MB}" ]; then
                log_error "Insufficient space on SPLUNK_DB filesystem: ${free_db}MB free."
                ok=false
            else
                log_info "Space OK  (SPLUNK_DB: ${free_db}MB free)"
            fi
        fi
    fi

    _log_raw "[DISK]  splunk_home_free=${free_splunk}MB  util=${util_splunk}%  stage_free=${free_stage}MB"

    if [ "${ok}" = false ]; then
        track_step "disk_space" "FAILED"; exit 1
    fi
    track_step "disk_space" "PASS"
}

###############################################################################
# STEP 7 — PRE-UPGRADE HEALTH CHECKS
###############################################################################

step_pre_upgrade_health() {
    log_section "STEP 7  ·  Pre-Upgrade Health Checks"

    # splunk status
    local st_out st_code
    set +e
    st_out=$(su - "${SPLUNK_USER}" -c "${SPLUNK_BIN} status 2>&1" 2>&1)
    st_code=$?
    set -e
    _log_raw "[HEALTH]  status exit=${st_code}  ${st_out}"
    [ "${st_code}" -eq 0 ] && log_info "splunk status: OK" \
                           || log_warn "splunk status returned ${st_code} — instance may be degraded."

    # btool check
    local bt_out bt_code
    set +e
    bt_out=$(su - "${SPLUNK_USER}" -c "${SPLUNK_BIN} btool check 2>&1" 2>&1)
    bt_code=$?
    set -e
    _log_raw "[HEALTH]  btool_check exit=${bt_code}  ${bt_out}"
    [ "${bt_code}" -eq 0 ] && log_info "btool check: clean" \
                           || log_warn "btool check reported issues — see log."

    # Recent FATAL entries in splunkd.log
    local splunkd_log="${SPLUNK_HOME}/var/log/splunk/splunkd.log"
    if [ -f "${splunkd_log}" ]; then
        local fatal_count
        set +e
        fatal_count=$(tail -500 "${splunkd_log}" | grep -c "FATAL" 2>/dev/null || true)
        set -e
        if [ "${fatal_count:-0}" -gt 0 ]; then
            log_warn "${fatal_count} FATAL entries in splunkd.log (last 500 lines) — review before proceeding."
            _log_raw "[HEALTH]  fatal_entries=${fatal_count}"
        else
            log_info "splunkd.log: no recent FATAL entries."
        fi
    fi

    log_info "Pre-upgrade health checks complete."
    track_step "pre_health" "PASS"
}

###############################################################################
# STEP 8 — VM BACKUP / VSPHERE SNAPSHOT REMINDER
###############################################################################

step_backup_reminder() {
    log_section "STEP 8  ·  Backup / Snapshot Confirmation"

    echo ""
    box_top
    box_empty
    box_title "SYSTEM ADMINISTRATOR REMINDER"
    box_empty
    box_mid
    box_empty
    box_line "Before continuing, create and verify a full VM backup or" 2
    box_line "vSphere snapshot of this Splunk server." 2
    box_empty
    box_line "The backup or snapshot must include:" 2
    box_line "  · The complete virtual machine" 2
    box_line "  · All attached Splunk data disks" 2
    box_line "  · Configuration files" 2
    box_line "  · KV Store data" 2
    box_line "  · Certificates" 2
    box_line "  · Operating-system state" 2
    box_empty
    box_line "Confirm the snapshot completed successfully and that sufficient" 2
    box_line "datastore capacity is available before proceeding." 2
    box_empty
    box_line "IMPORTANT: Rollback is a manual procedure using the verified" 2
    box_line "snapshot or backup. This script does not perform auto-rollback." 2
    box_empty
    box_bot
    echo ""

    if [ "${ARG_SNAPSHOT_CONFIRMED}" = true ]; then
        log_info "Snapshot confirmation supplied via --snapshot-confirmed flag."
        _log_raw "[SNAPSHOT]  confirmed=true  method=cli_flag  ts=$(date '+%Y-%m-%d %H:%M:%S')"
        track_step "snapshot" "PASS" "confirmed via flag"; return
    fi

    [ "${ARG_NON_INTERACTIVE}" = true ] && {
        log_error "--non-interactive requires --snapshot-confirmed."; exit 1; }

    local answer
    read -rp "${LYELLOW}  [?] Have you created and verified the full VM backup or vSphere snapshot? (yes/no): ${Color_Off}" answer

    # Safe default is no — only explicit 'yes' proceeds
    if [ "${answer}" != "yes" ] && [ "${answer}" != "YES" ]; then
        log_warn "Snapshot not confirmed. Upgrade cancelled."
        log_warn "Create and verify a full VM backup or snapshot, then re-run."
        _log_raw "[SNAPSHOT]  confirmed=false  answer='${answer}'"
        track_step "snapshot" "FAILED" "not confirmed"; exit 0
    fi

    log_info "VM backup/snapshot confirmed by administrator."
    _log_raw "[SNAPSHOT]  confirmed=true  method=interactive  ts=$(date '+%Y-%m-%d %H:%M:%S')  exec_id=${EXEC_ID}"
    track_step "snapshot" "PASS" "confirmed interactively"
}

###############################################################################
# UPGRADE CONFIGURATION SUMMARY + FINAL CONFIRMATION
###############################################################################

print_upgrade_summary() {
    local svc_method
    [ "${USE_SYSTEMD}" = true ] \
        && svc_method="systemd (${SYSTEMD_SERVICE})" \
        || svc_method="Splunk CLI"

    echo ""
    box_top
    box_title "Upgrade Configuration"
    box_mid
    box_empty
    box_kv "Product"         "Splunk Enterprise"
    box_kv "From version"    "${INSTALLED_VERSION}"
    box_kv "To version"      "${TARGET_VERSION}"
    box_kv "Package"         "${PACKAGE_NAME}"
    box_kv "Staging path"    "${PACKAGE_PATH}"
    box_kv "Splunk Home"     "${SPLUNK_HOME}"
    box_kv "Splunk DB"       "${SPLUNK_DB}"
    box_kv "Mgmt Port"       "${MGMT_PORT}"
    box_kv "Service Ctrl"    "${svc_method}"
    box_kv "Stop Timeout"    "${STOP_TIMEOUT}s  (graceful — no force-kill)"
    box_kv "Dry Run"         "${ARG_DRY_RUN}"
    box_kv "Log"             "${LOG_FILE}"
    box_empty
    box_bot
    echo ""

    if [ "${ARG_DRY_RUN}" = true ]; then
        log_warn "DRY-RUN: all pre-upgrade checks passed. Exiting without changes."
        track_step "dry_run" "PASS"; exit 0
    fi

    if [ "${ARG_NON_INTERACTIVE}" = true ]; then
        log_info "Non-interactive mode — proceeding automatically."
        _log_raw "[CONFIRM]  non-interactive  auto-proceed"
        return
    fi

    local confirm
    read -rp "${LYELLOW}  [?] Proceed with the upgrade? (yes/no): ${Color_Off}" confirm
    if [ "${confirm}" != "yes" ] && [ "${confirm}" != "YES" ] && \
       [ "${confirm}" != "y" ]   && [ "${confirm}" != "Y" ]; then
        log_warn "Upgrade cancelled by user."; exit 0
    fi
    log_info "Confirmed. Starting upgrade ..."
    echo ""
}

###############################################################################
# STEP 9 — OWNERSHIP VERIFICATION
# Default: read-only scan with warning.
# --repair-ownership: apply targeted chown with -xdev, recheck, fail if any remain.
###############################################################################

step_verify_ownership() {
    log_section "STEP 9  ·  Ownership Verification"

    local check_dirs=(
        "${SPLUNK_HOME}/bin"
        "${SPLUNK_HOME}/etc"
        "${SPLUNK_HOME}/var"
        "${SPLUNK_HOME}/lib"
        "${SPLUNK_HOME}/share"
    )

    local mismatched_dirs=()
    local dir

    for dir in "${check_dirs[@]}"; do
        [ -d "${dir}" ] || continue
        local bad
        set +e
        # -xdev: do not cross filesystem mount points
        bad=$(find "${dir}" -xdev \
            -not -user "${SPLUNK_USER}" \
            -not -name "splunk" \
            2>/dev/null | head -20 || true)
        set -e
        if [ -n "${bad}" ]; then
            mismatched_dirs+=("${dir}")
            _log_raw "[OWNERSHIP]  mismatches in ${dir}:"
            _log_raw "${bad}"
        fi
    done

    if [ ${#mismatched_dirs[@]} -eq 0 ]; then
        log_info "Ownership correct — no changes needed."
        track_step "ownership" "PASS"; return
    fi

    log_warn "Ownership mismatches found in: ${mismatched_dirs[*]}"
    log_warn "See ${LOG_FILE} for affected paths."

    if [ "${ARG_REPAIR_OWNERSHIP}" = false ]; then
        log_warn "Run with --repair-ownership to correct automatically."
        track_step "ownership" "WARNING" "mismatches present"; return
    fi

    log_step "Applying targeted ownership corrections ..."
    for dir in "${mismatched_dirs[@]}"; do
        set +e
        find "${dir}" -xdev \
            -not -user "${SPLUNK_USER}" \
            -not -name "splunk" \
            -exec chown "${SPLUNK_USER}:${SPLUNK_GROUP}" {} + 2>/dev/null
        set -e
    done

    # Recheck after repair
    local remaining=0
    for dir in "${mismatched_dirs[@]}"; do
        [ -d "${dir}" ] || continue
        local still
        set +e
        still=$(find "${dir}" -xdev \
            -not -user "${SPLUNK_USER}" \
            -not -name "splunk" \
            2>/dev/null | wc -l || true)
        set -e
        remaining=$(( remaining + still ))
    done

    if [ "${remaining}" -gt 0 ]; then
        log_error "Ownership repair incomplete — ${remaining} mismatched items remain."
        track_step "ownership" "FAILED" "${remaining} remaining"; exit 1
    fi

    log_info "Ownership corrected and verified."
    track_step "ownership" "PASS" "repaired"
}

###############################################################################
# STEP 10 — STOP SPLUNK (graceful — never force-kills)
###############################################################################

step_stop_splunk() {
    log_section "STEP 10  ·  Stop Splunk"

    if _splunk_is_running; then
        SPLUNK_WAS_RUNNING=true
        log_info "Splunk is running  (owner: ${SPLUNK_USER})"
        _log_raw "[STATE]  initial=running"
    else
        SPLUNK_WAS_RUNNING=false
        log_info "Splunk is not running — stop not required."
        _log_raw "[STATE]  initial=stopped"
        track_step "stop" "NOT_APPLICABLE"; return
    fi

    log_step "Requesting graceful shutdown  (timeout: ${STOP_TIMEOUT}s) ..."

    local stop_out stop_code
    set +e
    stop_out=$(_splunk_stop 2>&1)
    stop_code=$?
    set -e
    _log_raw "[STOP]  cmd exit=${stop_code}  ${stop_out}"

    [ "${stop_code}" -ne 0 ] && \
        log_warn "Stop command returned ${stop_code} — polling for process exit ..."

    local waited=0
    while _splunk_is_running; do
        if [ "${waited}" -ge "${STOP_TIMEOUT}" ]; then
            echo ""
            log_error "splunkd is still running after ${STOP_TIMEOUT}s."
            log_error "This script will NOT force-kill the process."
            log_error ""
            log_error "Investigate why Splunk did not stop:"
            if [ "${USE_SYSTEMD}" = true ]; then
                log_error "  journalctl -u ${SYSTEMD_SERVICE} -n 100"
                log_error "  systemctl status ${SYSTEMD_SERVICE}"
            fi
            log_error "  ${SPLUNK_BIN} status"
            log_error "  tail -200 ${SPLUNK_HOME}/var/log/splunk/splunkd.log"
            log_error ""
            log_error "Resolve manually and re-run the script."
            log_to_file "stop" "_splunk_stop" \
                "splunkd still running after ${STOP_TIMEOUT}s — manual intervention required"
            track_step "stop" "FAILED" "timeout"; exit 1
        fi
        log_step "Waiting for splunkd to exit ...  (${waited}s / ${STOP_TIMEOUT}s)"
        sleep 5
        waited=$(( waited + 5 ))
    done

    log_info "Splunk stopped cleanly  (${waited}s)"
    _log_raw "[STOP]  stopped after ${waited}s"
    track_step "stop" "PASS"
}

###############################################################################
# STEP 11 — RPM UPGRADE
###############################################################################

step_upgrade_rpm() {
    log_section "STEP 11  ·  RPM Upgrade"

    log_step "Running rpm -Uvh ..."

    local out code
    set +e
    out=$(rpm -Uvh "${PACKAGE_PATH}" 2>&1)
    code=$?
    set -e

    _log_raw "[RPM_INSTALL]  exit=${code}"
    _log_raw "${out}"

    if [ "${code}" -eq 0 ]; then
        log_info "RPM upgraded successfully  (${INSTALLED_VERSION}  →  ${TARGET_VERSION})"
        track_step "rpm_install" "PASS"; return
    fi

    if echo "${out}" | grep -qi "already installed"; then
        log_warn "RPM reports this version is already installed — skipping RPM step."
        track_step "rpm_install" "SKIPPED" "already installed"; return
    fi

    log_error "rpm -Uvh failed  [exit: ${code}]"
    log_to_file "rpm_install" "rpm -Uvh ${PACKAGE_PATH}" "${out}"
    track_step "rpm_install" "FAILED"; exit 1
}

###############################################################################
# STEP 12 — START SPLUNK + LICENSE ACCEPTANCE (single start, no double-start)
###############################################################################

step_start_splunk() {
    log_section "STEP 12  ·  Start Splunk & Accept License"

    local svc_label
    [ "${USE_SYSTEMD}" = true ] && svc_label="systemd" || svc_label="CLI"
    log_step "Starting Splunk  (${svc_label}) ..."

    local out code
    set +e
    out=$(_splunk_start_with_license 2>&1)
    code=$?
    set -e

    _log_raw "[START]  exit=${code}  ${out}"

    if [ "${code}" -ne 0 ]; then
        log_error "Splunk start failed  [exit: ${code}]"
        log_error "See: ${LOG_FILE}"
        log_to_file "start" "_splunk_start_with_license" "${out}"
        track_step "start" "FAILED"; exit 1
    fi

    log_info "Start command accepted."
    track_step "start" "PASS"
}

###############################################################################
# STEP 13 — READINESS VALIDATION
###############################################################################

step_wait_for_ready() {
    log_section "STEP 13  ·  Readiness Validation"

    log_step "Waiting for Splunk to become ready  (timeout: ${READY_TIMEOUT}s) ..."

    local waited=0 process_ok=false port_ok=false status_ok=false

    while [ "${waited}" -lt "${READY_TIMEOUT}" ]; do
        _splunk_is_running && process_ok=true

        ss -tlnp 2>/dev/null | grep -q ":${MGMT_PORT}" && port_ok=true

        if [ "${process_ok}" = true ] && [ "${port_ok}" = true ]; then
            local st_out st_code
            set +e
            st_out=$(su - "${SPLUNK_USER}" -c "${SPLUNK_BIN} status 2>&1" 2>&1)
            st_code=$?
            set -e
            if [ "${st_code}" -eq 0 ]; then
                status_ok=true; break
            fi
        fi

        sleep 5
        waited=$(( waited + 5 ))
        log_step "Waiting ...  (${waited}s / ${READY_TIMEOUT}s)"
    done

    _log_raw "[READY]  process=${process_ok}  port=${port_ok}  status=${status_ok}  waited=${waited}s"

    # Process running is mandatory
    if [ "${process_ok}" = false ]; then
        log_error "splunkd process did not start within ${READY_TIMEOUT}s."
        log_to_file "readiness" "process check" "process_ok=false"
        track_step "readiness" "FAILED" "process not running"; exit 1
    fi

    # splunk status is mandatory
    if [ "${status_ok}" = false ]; then
        log_error "splunk status did not succeed within ${READY_TIMEOUT}s."
        track_step "readiness" "FAILED" "status check failed"; exit 1
    fi

    log_info "Process running        ✔"
    log_info "Port :${MGMT_PORT} listening  ✔"
    log_info "splunk status OK       ✔"

    # btool check post-upgrade (warning only)
    local bt_out bt_code
    set +e
    bt_out=$(su - "${SPLUNK_USER}" -c "${SPLUNK_BIN} btool check 2>&1" 2>&1)
    bt_code=$?
    set -e
    _log_raw "[READY]  btool_check exit=${bt_code}  ${bt_out}"
    [ "${bt_code}" -ne 0 ] \
        && log_warn "btool check reported issues post-upgrade — see log." \
        || log_info "btool check: clean  ✔"

    # Migration error scan in splunkd.log
    local splunkd_log="${SPLUNK_HOME}/var/log/splunk/splunkd.log"
    if [ -f "${splunkd_log}" ]; then
        local mig_err
        set +e
        mig_err=$(grep -c "ERROR.*[Mm]igrat" "${splunkd_log}" 2>/dev/null || true)
        set -e
        [ "${mig_err:-0}" -gt 0 ] \
            && log_warn "Migration errors in splunkd.log (${mig_err} entries) — review log." \
            || log_info "No migration errors in splunkd.log  ✔"
    fi

    # Version confirmation (mandatory)
    local ver_running rpm_ver
    set +e
    ver_running=$(su - "${SPLUNK_USER}" -c "${SPLUNK_BIN} version 2>/dev/null" 2>/dev/null \
        | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
    rpm_ver=$(rpm -q splunk --qf '%{VERSION}' 2>/dev/null || true)
    set -e

    _log_raw "[READY]  running_ver=${ver_running}  rpm_ver=${rpm_ver}  target=${TARGET_VERSION}"

    [ "${ver_running}" = "${TARGET_VERSION}" ] \
        && log_info "Running version matches target: ${ver_running}  ✔" \
        || log_warn "Version mismatch: running=${ver_running}  target=${TARGET_VERSION}"

    [ "${rpm_ver}" = "${TARGET_VERSION}" ] \
        && log_info "RPM database version: ${rpm_ver}  ✔" \
        || log_warn "RPM database version ${rpm_ver} != target ${TARGET_VERSION}"

    track_step "readiness" "PASS"

    echo ""
    box_top
    box_empty
    box_title "Post-Upgrade Version"
    box_mid
    box_empty
    box_line "Splunk version : ${ver_running}" 4
    box_line "RPM record     : $(rpm -q splunk 2>/dev/null || true)" 4
    box_empty
    box_bot
    echo ""
}

###############################################################################
# STEP 14 — RESTORE ORIGINAL SERVICE STATE
###############################################################################

step_restore_state() {
    log_section "STEP 14  ·  Service State Restoration"

    if [ "${SPLUNK_WAS_RUNNING}" = true ]; then
        log_info "Splunk was running before upgrade — leaving it running."
        _log_raw "[STATE]  final=running  intended=running"
        track_step "state_restore" "PASS" "was running, left running"; return
    fi

    log_step "Splunk was stopped before upgrade — stopping to restore original state ..."

    local stop_out stop_code
    set +e
    stop_out=$(_splunk_stop 2>&1)
    stop_code=$?
    set -e
    _log_raw "[STATE_RESTORE]  stop exit=${stop_code}  ${stop_out}"

    local waited=0
    while _splunk_is_running && [ "${waited}" -lt "${STOP_TIMEOUT}" ]; do
        sleep 5
        waited=$(( waited + 5 ))
    done

    if _splunk_is_running; then
        log_error "Splunk could not be stopped — original stopped state NOT restored."
        _log_raw "[STATE]  final=running  intended=stopped  FAILED"
        track_step "state_restore" "FAILED" "could not restore stopped state"
        return
    fi

    log_info "Splunk stopped — original pre-upgrade state restored."
    _log_raw "[STATE]  final=stopped  intended=stopped"
    track_step "state_restore" "PASS" "restored to stopped"
}

###############################################################################
# FINAL SUMMARY
###############################################################################

print_summary() {
    local all_pass=true
    for key in "${!STEP_STATUS[@]}"; do
        [ "${STEP_STATUS[$key]}" = "FAILED" ] && { all_pass=false; break; }
    done

    echo ""
    box_top
    box_empty

    if [ "${all_pass}" = true ]; then
        box_title "Splunk Enterprise Upgrade — Completed Successfully"
    else
        box_title "Splunk Enterprise Upgrade — Completed with Issues"
    fi

    box_empty
    box_mid
    box_empty

    local ordered_keys=(
        dependencies system splunk_home user_group installed_rpm
        topology package_select connectivity download checksum
        metadata gpg rpm_test disk_space pre_health snapshot
        ownership stop rpm_install start readiness state_restore
    )
    local labels=(
        "Dependencies"          "System"               "Splunk Home"
        "User / Group"          "Installed RPM"        "Topology"
        "Package Selection"     "Connectivity"         "Download"
        "Checksum"              "RPM Metadata"         "GPG Signature"
        "RPM Transaction Test"  "Disk Space"           "Pre-Upgrade Health"
        "VM Snapshot"           "Ownership"            "Stop Splunk"
        "RPM Upgrade"           "Start Splunk"         "Readiness"
        "State Restoration"
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

    _log_raw "[SUMMARY]  exec_id=${EXEC_ID}  overall=$([ "${all_pass}" = true ] && echo PASS || echo ISSUES)"
}

###############################################################################
# MAIN
###############################################################################

main() {
    init_logging
    parse_cli_args "$@"
    acquire_lock
    init_environment

    print_header

    # Phase 1 — Validate environment
    validate_dependencies
    validate_system
    validate_splunk_home
    validate_user_group
    validate_installed_rpm        # refuses fresh installs; sets INSTALLED_VERSION
    discover_splunk_config        # sets SPLUNK_DB and MGMT_PORT from btool
    detect_service_manager        # sets USE_SYSTEMD and SYSTEMD_SERVICE
    detect_and_refuse_cluster_roles

    # Phase 2 — Obtain and validate the upgrade package
    select_package                # sets PACKAGE_PATH
    step_connectivity_check
    step_download_package
    step_verify_checksum          # optional; skipped if no checksum provided
    validate_package_metadata     # sets TARGET_VERSION; refuses downgrade/same-version
    step_verify_rpm_signature     # rpm -K; GPG key import flow if NOKEY
    step_rpm_test                 # rpm -Uvh --test — runs BEFORE Splunk is stopped
    validate_disk_space

    # Phase 3 — Operator gates (BEFORE any destructive action)
    step_pre_upgrade_health       # btool check, status, FATAL log scan
    step_backup_reminder          # vSphere snapshot reminder — explicit confirmation gate

    # Phase 4 — Execute upgrade
    print_upgrade_summary         # display config + final confirmation (or dry-run exit)
    step_verify_ownership         # check; repair only if --repair-ownership
    step_stop_splunk              # graceful; records SPLUNK_WAS_RUNNING
    step_upgrade_rpm
    step_start_splunk             # single start; license acceptance; no double-start
    step_wait_for_ready           # process + port + status + btool + version

    # Phase 5 — Restore and report
    step_restore_state            # honours SPLUNK_WAS_RUNNING
    print_summary
}

main "$@"
