# Splunk Enterprise Upgrade Script

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
