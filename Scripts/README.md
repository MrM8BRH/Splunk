<details>
<summary><b>🟢 Splunk Enterprise Installation Script</b></summary>

**File:** `splunk_enterprise_install.sh`  
**Version:** 1.1.3  
**Author:** @MrM8BRH

## Overview

This script performs a **production‑ready, automated installation** of Splunk Enterprise on a fresh RPM‑based Linux system. It handles everything from system preparation, dependency installation, RPM download, user/group creation, systemd service setup, and initial admin credentials configuration – all with extensive logging and interactive prompts.

> **⚠️ Important**  
> - Only for **fresh installations** on RHEL / Rocky / AlmaLinux / CentOS (x86_64).  
> - Must be run as **root**.  
> - Default admin credentials: `admin` / `Splunk@Cisco` – **change immediately after login**.

---

## Prerequisites

- **OS**: RHEL / Rocky / AlmaLinux / CentOS 8+ (x86_64) with `systemd`.
- **Packages**: `curl`, `wget`, `rpm`, `flock`, `sha512sum`, `ss`, `awk`, `grep`, `sed`, `find`, `hostnamectl`, `systemctl`, `dnf`, `ping`, `uname`, `tee` (most are pre‑installed).
- **Internet**: Outbound HTTPS (443) to `download.splunk.com` and `www.splunk.com` (for RPM download and checksum verification).
- **SELinux**: Will be set to `disabled` permanently (requires reboot).
- **Firewall**: `firewalld` will be stopped and disabled (use cloud/network security groups instead).
- **Hardware**: At least 12 CPU cores and 12 GB RAM (recommended; below that gives a warning only).

---

## Usage Examples

### 1. Standard interactive installation (recommended)

```bash
sudo ./splunk_enterprise_install.sh
```

The script will guide you through:
- System validation and dependency checks
- Hostname configuration (press Enter to keep current)
- Optional kernel network tuning for Indexers
- Download and installation of Splunk Enterprise
- Setup of systemd service
- Creation of default admin user (`admin` / `Splunk@Cisco`)

### 2. Non‑interactive (requires modifications)

The script does not natively support fully non‑interactive mode. If you need automation, you can pre‑set environment variables or modify the script to skip prompts (e.g., set `ENABLE_KERNEL_NET_TUNING` and `INPUT_HOSTNAME`). However, the default interaction is intentional for safety.

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Pre‑flight Checks** | Architecture, OS family, disk space, static IP, NTP configuration, CPU/RAM. |
| **Dependency Installation** | Installs EPEL, CRB repository, core utilities, and Splunk‑required libraries. |
| **Hostname Configuration** | Prompts for FQDN; adds `/etc/hosts` entry automatically if missing. |
| **SELinux & Firewall** | Disables SELinux and firewalld (system reboot required for SELinux to fully apply). |
| **THP Disable** | Creates a systemd service to disable Transparent Huge Pages permanently. |
| **Kernel Tuning** | Optional sysctl settings for Indexer workloads (prompts for confirmation). |
| **RPM Download** | Scrapes the official Splunk download page for the latest RPM, verifies SHA256/MD5 checksum. |
| **User/Group Setup** | Creates the `splunk` user/group with appropriate permissions. |
| **Systemd Integration** | Uses Splunk’s official `enable boot-start` command to generate a clean unit file; appends recommended limits. |
| **Admin Credentials** | Sets default credentials via `user-seed.conf` (consumed on first start). |
| **Service Management** | Starts Splunk via systemd and waits for the management port (8089) to be ready. |
| **Comprehensive Logging** | All outputs are logged to `/var/log/splunk-install/` with a symlink to `latest.log`. |
| **Execution Lock** | Prevents concurrent runs using `flock`. |
| **Reboot Prompt** | Asks to reboot after installation (SELinux and THP changes require it). |

---

## Final Notes

- **Default Credentials**: `admin` / `Splunk@Cisco` – **change immediately after first login** using the web UI or CLI:
  ```bash
  /opt/splunk/bin/splunk edit user admin -password '<new-password>' -auth admin:Splunk@Cisco
  ```
- **Security**: The script uses `user-seed.conf` which is automatically deleted after first start – no credentials are left behind.
- **Reboot**: A reboot is recommended to finalise SELinux and THP changes. The script will prompt you to reboot.
- **Logs**: Check `/var/log/splunk-install/latest.log` for debugging.
- **Backup**: Always back up your system before running installation scripts.
- **Clusters**: This script is for **standalone** installations only. For distributed environments, use the Splunk official deployment guides.

**License:** Provided as‑is; use at your own risk. Feel free to adapt to your needs.

</details>

<details>
<summary><b>🟢 Splunk Enterprise Upgrade Script</b></summary>

**File:** `splunk_enterprise_upgrade.sh`  
**Version:** 3.1.0  
**Author:** @MrM8BRH

## Overview

This script upgrades an existing RPM‑managed Splunk Enterprise **standalone** installation to a newer version. It performs comprehensive pre‑flight checks, downloads the RPM (with caching), verifies GPG signatures and SHA512 checksums, stops Splunk gracefully, applies the RPM upgrade, and restores the original service state.

> **⚠️ Important**  
> - Only for **standalone** Splunk instances (no indexer clusters, search head clusters, or deployers).  
> - Requires an existing RPM‑based installation (TAR‑based or fresh installs are **not** supported).  
> - Must be run as **root**.

---

## Prerequisites

- **OS**: RHEL / Rocky / AlmaLinux / CentOS (x86_64) with systemd or SysV init.
- **Packages**: `curl`, `wget`, `rpm`, `flock`, `sha512sum`, `ss`, `awk`, `grep`, `sed`, `find`, etc. (most are pre‑installed).
- **Splunk**: Already installed via RPM, and the `splunk` user exists.

---

## Command‑Line Options

| Flag | Description |
|------|-------------|
| `--package PATH` | Use a local RPM file (skips download). |
| `--url URL` | Download from a Splunk CDN URL (must start with `https://download.splunk.com/` and end with `.rpm`). |
| `--checksum SHA512` | Manually provide the expected SHA512 hash. |
| `--auto-checksum` | Automatically fetch the `.sha512` file from the CDN. |
| `--gpg-key-url URL` | Override the default Splunk GPG key URL. |
| `--repair-ownership` | Automatically correct ownership mismatches (default: warn only). |
| `--keep-package` | Keep the RPM after successful upgrade (default: delete). |
| `--dry-run` | Validate everything but do **not** stop Splunk or install anything. |
| `--non-interactive` | Suppress all prompts; requires `--snapshot-confirmed` and either `--package` or `--url`. |
| `--snapshot-confirmed` | Acknowledge that a full VM backup/snapshot was taken (mandatory in non‑interactive mode). |
| `--help` | Show usage. |

---

## Usage Examples

### 1. Interactive upgrade (prompts for package selection and confirmations)

```bash
sudo ./splunk_enterprise_upgrade.sh
```

### 2. Non‑interactive upgrade with latest version (auto‑detect URL)
```
# Get the latest RPM URL
LATEST_URL=$(curl -s https://www.splunk.com/en_us/download/splunk-enterprise.html | \
    grep -oP 'https://download\.splunk\.com/products/splunk/releases/[^"]+x86_64\.rpm' | head -1)

# Run the upgrade
sudo ./splunk_enterprise_upgrade.sh \
    --non-interactive \
    --snapshot-confirmed \
    --auto-checksum \
    --repair-ownership \
    --url "$LATEST_URL"
```

### 3. Upgrade using a locally downloaded RPM (no download)
```
sudo ./splunk_enterprise_upgrade.sh \
    --non-interactive \
    --snapshot-confirmed \
    --package /path/to/splunk-10.4.0-f798d4d49089.x86_64.rpm
```

### 4. Dry‑run (pre‑flight validation only)
```
sudo ./splunk_enterprise_upgrade.sh --dry-run
```

### Key Features
- RPM Cache – Downloads are cached in `/var/tmp/splunk-rpm-cache/` to avoid re‑downloading the same RPM on subsequent runs.
- Graceful Stop – Never force‑kills Splunk; respects the configured STOP_TIMEOUT (default 180s) and fails cleanly if Splunk doesn't stop.
- GPG Verification – Automatically imports the Splunk signing key (if missing) after confirmation.
- SHA512 Checksum – Supports `--auto-checksum` to verify integrity against Splunk’s official `.sha512` file.
- Systemd Integration – Automatically creates the systemd unit if missing (using `splunk enable boot-start`).
- Ownership Repair – Optionally fixes file ownership mismatches (`--repair-ownership`).
- State Restoration – If Splunk was stopped before the upgrade, it will be stopped again after the upgrade (to preserve the original state).


### Final Notes
- Always take a full VM snapshot or backup before running the upgrade.
- The script does not perform automatic rollback – you must restore from the snapshot if something goes wrong.
- For clustered environments, use the official Splunk rolling‑upgrade procedure instead.

**License:** This script is provided as‑is; use at your own risk. Feel free to adapt it to your needs.

</details>
