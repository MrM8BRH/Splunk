<details>
<summary><b>Splunk Deployment Specifications</b></summary>

## Distributed Deployment
### Server Requirements
1. **Search Heads** (2 instances)
   - **Purpose:** SIEM (Enterprise Security Application) and application monitoring (F5, FortiGate, CrowdStrike, etc.)
2. **Deployment Server** (1 instance)
   - **Purpose:** Manage Splunk agents (Windows, Linux, etc.) and deploy add-ons
3. **Indexer Server** (1 instance)
   - **Purpose:** Store and process large data volumes
4. **Syslog/SC4S Server** (Choose one)
   - **Option 1:** Syslog Server
   - **Option 2:** SC4S Server
   - **Recommendation:** SC4S for improved scalability and performance

### Partitioning Guidelines
- **Operating System:** RHEL/RockyOS with Ext4 LVM partitioning
- **Splunk Servers:**
  - **Root (`/`):** 15 GB
  - **Swap:** 8 GB
  - **`/tmp`:** 10 GB
  - **`/var`:** 15 GB
  - **`/boot`:** 1 GB
  - **`/boot/efi`:** 1 GB
  - Remaining storage allocated to **`/opt`**
- **Syslog Server:**
  - **Root (`/`):** 20 GB
  - **Swap:** 8 GB
  - **`/tmp`:** 10 GB
  - **`/boot`:** 1 GB
  - **`/boot/efi`:** 1 GB
  - **`/opt`:** 20 GB
  - Remaining storage allocated to **`/var`**
- **SC4S Server:**
  - **Root (`/`):** 20 GB
  - **Swap:** 8 GB
  - **`/tmp`:** 10 GB
  - **`/boot`:** 1 GB
  - **`/boot/efi`:** 1 GB
  - Remaining storage allocated to **`/var`**

---

## Single Deployment

### Server Requirements

1. **Splunk Server** (1 instance)
   - **Roles:** Search, storage, agent management, and add-on deployment
   - **Partitioning:**
     - **Swap:** 8 GB
     - **`/tmp`:** 10 GB
     - **Root (`/`):** 10 GB
     - **`/boot`:** 1 GB
     - **`/boot/efi`:** 1 GB
     - Remaining storage for **`/opt`**

2. **SC4S Server** (1 instance)
   - **Purpose:** Agentless data ingestion (firewalls, routers, switches, etc.)
   - **Partitioning:**
     - **Swap:** 8 GB
     - **`/tmp`:** 10 GB
     - **`/opt`:** 10 GB
     - **`/boot`:** 1 GB
     - **`/boot/efi`:** 1 GB
     - Remaining storage for **`/var`**

---

## Indexer Cluster Deployment

### System Requirements

| System | VM Qty | RAM/vRAM | CPU/vCPU | Storage/VM | IOPS/VM | Retention Period |
|--------|--------|----------|----------|------------|---------|------------------|
| Splunk Search Head | 2 | 32 GB | 16 physical cores (or 32 vCPU) | 300 GB | 1200 | N/A |
| Splunk Indexer | 3 | 16 GB | 16 physical cores (or 32 vCPU) | 4 TB | 1200 | 1 year |
| Manager Node | 1 | 16 GB | 8 physical cores (or 12 vCPU) | 100 GB | 800 | N/A |
| Syslog-ng Server | 1 | 16 GB | 8 physical cores (or 12 vCPU) | 200 GB | 800 | 5 days |

---

## All-In-One Deployment

### System Requirements

| System | VM Qty | RAM/vRAM | CPU/vCPU | Storage/VM | IOPS/VM | Retention Period |
|--------|--------|----------|----------|------------|---------|------------------|
| Splunk Search & Indexer | 1 | 32 GB | 16 physical cores (or 32 vCPU) | 1 TB | 1200 | N/A |
| Syslog-ng Server | 1 | 16 GB | 8 physical cores (or 12 vCPU) | 200 GB | 800 | 5 days |

---

## General Notes

- **OS:** Use RHEL/RockyOS (latest version) for all servers
- **CPU Speed:** Minimum 2 GHz/core for physical/virtual CPUs
</details>

<details>
<summary><b>Preparing a System Before Splunk Installation</b></summary>
  
<details>
<summary><b>Update the system & Install additional tools</b></summary>

RHEL family
```
yum update -y
yum install -y dnf
dnf install -y net-tools nano bind-utils chkconfig wget net-tools tcpdump fio bzip2 sysstat elfutils polkit.x86_64 cloud-utils-growpart coreutils findutils procps shadow-utils
```
Debian family
```
apt update -y
apt full-upgrade -y
apt install -y net-tools nano wget net-tools tcpdump screen iotop htop ioping fio bzip2 sysstat elfutils cloud-guest-utils coreutils findutils procps passwd
```
</details>

<details>
<summary><b>Change Hostname</b></summary>

```
hostnamectl
hostnamectl set-hostname host.domain.com
```
</details>

<details>
<summary><b>Change IP Address, DNS Server, Gateway</b></summary>

```
nmtui
```
</details>

<details>
<summary><b>Change NTP Server & Timezone</b></summary>

#### NTP
```
- Install (Chrony)
  dnf install chrony -y

- Verify
  timedatectl
  chronyc sources

- Configuration (Chrony)
  nano /etc/chrony.conf
  # Example:
  # server 0.pool.ntp.org iburst
  # server <IP_Address> iburst

- Service (Chrony)
  systemctl status chronyd
  systemctl start chronyd
  systemctl enable chronyd
```

#### Timezone

```
timedatectl
timedatectl set-timezone Asia/Jerusalem
```

</details>

<details>
<summary><b>Disable SELinux</b></summary>

SELinux can interfere with Splunk operations. Set it to `permissive` or `disabled`:
```
# Check the current status and mode of SELinux.
sestatus

# Opens the SELinux configuration file using the nano text editor.
nano /etc/selinux/config

# A configuration option that can be set in the SELinux configuration file to disable SELinux on the system,
# preventing it from enforcing security policies.
SELINUX=disabled
```
Apply immediately:
```
sudo setenforce 0
```
</details>

<details>
<summary><b>Set Ulimits</b></summary>

Increase file descriptors and process limits for the splunk user

Create or edit a file in `/etc/security/limits.d/` to set limits for the Splunk user (default: `splunk`):
```
sudo nano /etc/security/limits.d/99-splunk.conf
```
Add the following lines (replace `splunk` with your Splunk user if different):
```
splunk soft data 19531250
splunk hard data 19531250
splunk soft nofile 64000
splunk hard nofile 64000
splunk soft nproc 16000
splunk hard nproc 16000
```
Verify after reboot:
```
ulimit -n  # Should return 65535
ulimit -u  # Should return 20480
ulimit -d  # Should return 19531250
```
</details>

<details>
<summary><b>Disable Firewall</b></summary>

```
systemctl stop firewalld
systemctl disable firewalld
```
</details>


<details>
<summary><b>Disable Transparent Huge Pages (THP)</b></summary>

Splunk recommends disabling THP for performance optimization

Option1
*   `nano /etc/systemd/system/disable-thp.service`
```
[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
```

```
systemctl daemon-reload
systemctl start disable-thp
systemctl enable disable-thp
```
Option2
```bash
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
```
Persist this change across reboots by editing `/etc/rc.local`.
</details>

<details>
<summary><b>Increase Kernel Buffer Sizes</b></summary>

- `nano /etc/sysctl.conf`
```
net.core.rmem_default = 33554432
net.core.rmem_max = 33554432
net.core.netdev_max_backlog = 10000
```
Then run the following to reload the settings: 
```
/sbin/sysctl -p
```
</details>

<details>
<summary><b>Firewall Rules (Host & Network)</b></summary>

This is a diagram of Splunk components and network ports that are commonly used in a Splunk Enterprise environment. Firewall rules often need to be updated to allow communication on ports 8000, 8089, 9997, 8080 and 514.

![Ports](https://github.com/MrM8BRH/Splunk/assets/34133187/73a05f58-7be5-4b71-ada3-46487459bbc1)

Open required ports (adjust based on your deployment):
```bash
sudo firewall-cmd --permanent --add-port=8000/tcp  # Splunk Web
sudo firewall-cmd --permanent --add-port=8089/tcp  # Management port
sudo firewall-cmd --permanent --add-port=9997/tcp  # Forwarder data ingestion
sudo firewall-cmd --reload
```
Verify open ports:
```bash
sudo firewall-cmd --list-ports
```
#### CrowdStrike
```
https://api.us-2.crowdstrike.com
https://firehose.us-2.crowdstrike.com
```
#### Splunk
```
https://www.splunk.com/
https://login.splunk.com/
https://download.splunk.com
https://splunkbase.splunk.com/
```
</details>

```diff
- After completing the above, restart the system
reboot
```
</details>

<details>
<summary><b>Splunk Enterprise (Linux)</b></summary>

```
# Install Splunk using RPM:
rpm -i splunk_package_name.rpm

# Install Splunk using Tar:
tar xvzf splunk_package_name.tgz -C /opt

# Accept the Splunk license and verify the installed version
/opt/splunk/bin/splunk version --accept-license

# Change servername & hostname
/opt/splunk/bin/splunk set servername host.domain.com
/opt/splunk/bin/splunk set default-hostname host.domain.com

# Enable boot-start
/opt/splunk/bin/splunk enable boot-start -systemd-managed 1 -user splunk -group splunk # 1
/opt/splunk/bin/splunk enable boot-start -systemd-managed 1 -create-polkit-rules 1 -user splunk -group splunk # 2

# Permissions
chown -R splunk:splunk /opt/splunk
chmod -R 755 /opt/splunk
```
[Configure Linux systems running systemd](https://help.splunk.com/en/splunk-enterprise/administer/manage-workloads/10.2/set-up-linux-for-workload-management/configure-linux-systems-running-systemd)

[Enable workload management)](https://help.splunk.com/en/splunk-enterprise/administer/manage-workloads/10.2/configure-workload-management/enable-workload-management)

### Splunkd.service
Cgroup version
```
# Checking cgroup Version via `/proc/filesystems`
grep cgroup /proc/filesystems

# Output Interpretation
## Systems Supporting cgroupv2
nodev   cgroup
nodev   cgroup2

## Systems with cgroupv1 Only
nodev   cgroup
```
Edit the Splunk systemd unit file to adjust resource limits
```
nano /etc/systemd/system/Splunkd.service
```
Add or update the following values as required (For **cgroups v2**):
```
[Service]
LimitNOFILE=65536
CPUWeight=100
LimitDATA=20000000000
LimitFSIZE=infinity
TasksMax=8192
MemoryMax=infinity
```
Validate the systemd unit file syntax
```
systemd-analyze verify /etc/systemd/system/Splunkd.service
```
Clean systemd environment
```
systemctl daemon-reexec
systemctl daemon-reload
```
Enable Splunkd to start at boot and start the service immediately
```
systemctl enable --now Splunkd.service
```
Troubleshooting
```
# Step 1: Check Splunkd service status if startup fails
systemctl status Splunkd

# Step 2: Stop Splunkd service and reset systemd failure state
systemctl stop Splunkd
systemctl reset-failed Splunkd

# Step 3: Fix ownership and ensure required Splunk runtime directories exist
chown -R splunk:splunk /opt/splunk

mkdir -p /opt/splunk/var/run/splunk/config/validate/tmp
mkdir -p /opt/splunk/var/log/splunk

chown -R splunk:splunk /opt/splunk/var
chmod -R u+rwX /opt/splunk/var
```
</details>

<details>
<summary><b>Enable SSL</b></summary>
  
*   `nano /opt/splunk/etc/system/local/web.conf`
```text-plain
[settings]
max_upload_size = 2048
enableSplunkWebSSL = true
splunkdConnectionTimeout = 600
```
</details>

<details>
<summary><b>Optimization Recommendations</b></summary>
  

- `nano /opt/splunk/etc/system/local/server.conf`
```
[general]
conf_cache_memory_optimization = true
sessionTimeout = 8h
```
In the [limits.conf](https://docs.splunk.com/Documentation/Splunk/latest/Admin/Limitsconf) file, consider reviewing and adjusting the following settings to optimize Splunk performance:
*   `nano /opt/splunk/etc/system/local/limits.conf`
```
[default]
max_mem_usage_mb = 24576

[searchresults]
maxresultrows = 100000

# The maximum number of concurrent historical searches in the search head.
total_search_concurrency_limit = auto

# The base number of concurrent historical searches.
base_max_searches = 24

# Max real-time searches = max_rt_search_multiplier x max historical searches.
max_rt_search_multiplier = 1

# The maximum number of concurrent historical searches per CPU.
max_searches_per_cpu = 2

[scheduler]
# The maximum number of searches the scheduler can run, as a percentage
# of the maximum number of concurrent searches.
max_searches_perc  = 75

# Fraction of concurrent scheduler searches to use for auto summarization.
auto_summary_perc  = 50
```
These adjustments should be aligned with our system requirements and available resources.
</details>
  
<details>
<summary><b>Forwarding Splunk's internal logs to the indexers</b></summary>

*    `nano /opt/splunk/etc/system/local/outputs.conf`
```
# Turn off indexing
# [indexAndForward]
# index = false

[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = 192.168.1.50:9997

[tcpout-server://192.168.1.50:9997]
```
</details>

<details>
<summary><b>Indexer Server</b></summary>

```
- Settings → Forwarding and reciving → Configure receiving
- Settings → Licensing
- Settings → Indexes - Add indexes like: wineventlog, linux, windows ... etc.
- Install Addons
```
Disable Splunk Web (optional)

`/opt/splunk/bin/splunk disable webserver`

---

`sudo nano /opt/splunk/etc/system/local/web.conf`
* Add the following lines.
```
[settings]
startwebserver = 0
```
* Save the changes and exit the text editor.
* Restart the Splunk service for the changes to take effect. 
```
sudo systemctl restart splunk
```
</details>

<details>
<summary><b>Log Retention</b></summary>

Storage Calculation
```
Retention:
(Daily average indexing rate) x (retention policy) * 1/2

Data model acceleration:
Storage per day * 3.14

Storage = Retention + DMA
```

`nano /opt/splunk/etc/system/local/indexes.conf`, `nano /opt/splunk/etc/apps/<?>/<local/default>/indexes.conf`
```
[default]
# maxHotSpanSecs sets the maximum age of data in the "hot" bucket to 90 days.
maxHotSpanSecs = 7776000

# frozenTimePeriodInSecs sets the maximum age of data in the "cold" bucket to 275 days.
frozenTimePeriodInSecs = 23760000
```
![idx-bucket](https://github.com/MrM8BRH/Splunk/assets/34133187/0a490730-a70b-4162-ab32-74c44ece95ff)

Bucket States Overview
| Bucket State | Description | Searchable? |
|--------------|-------------|-------------|
| Hot          | New data is written to hot buckets. Each index has one or more hot buckets. | Yes         |
| Warm         | Buckets rolled from hot. New data is not written to warm buckets. An index has many warm buckets. | Yes         |
| Cold         | Buckets rolled from warm and moved to a different location. An index has many cold buckets. | Yes         |
| Frozen       | Buckets rolled from cold. The indexer deletes frozen buckets, but you can choose to archive them first. Archived buckets can later be thawed. | No          |
| Thawed       | Buckets restored from an archive. If you archive frozen buckets, you can later return them to the index by thawing them. | Yes         |

Default Index (defaultdb) Directory Structure
| Bucket State | Default Location                                       | Notes                                                                    |
|--------------|--------------------------------------------------------|--------------------------------------------------------------------------|
| Hot          | `$SPLUNK_HOME/var/lib/splunk/defaultdb/db/*`          | Each hot bucket occupies its own subdirectory.                            |
| Warm         | `$SPLUNK_HOME/var/lib/splunk/defaultdb/db/*`          | Each warm bucket occupies its own subdirectory.                           |
| Cold         | `$SPLUNK_HOME/var/lib/splunk/defaultdb/colddb/*`      | Each cold bucket occupies its own subdirectory. When warm buckets roll to cold, they get moved to this directory. |

Configuring Frozen Storage

`nano /opt/splunk/etc/system/local/indexes.conf`, `nano /opt/splunk/etc/apps/<?>/<local/default>/indexes.conf`
```
coldToFrozenDir = /whatever/path/you/want 
```

Volumes Configuraiton 
```
[volume:hot_storage]
path = /mnt/fast_disk
#Optional limits the volume size to 60 GB
maxVolumeDataSizeMB = 61440

[volume:cold_storage]
path = /mnt/slow_disk
#Optional limits the volume size to 50 GB
maxVolumeDataSizeMB = 51200
```
</details>

<details>
<summary><b>Deployment Server</b></summary>

```
- Settings → Licensing
- Settings → Server settings → Email settings
- Settings → Distributed search → Search peers (Indexers + Search heads)
- Settings → Monitoring Console → Settings → Alerts Setup
- Settings → Monitoring Console → Settings → Forwarder Monitoring Setup
- Settings → Monitoring Console → Settings → General Setup [Standalone → Distributed]
   Edit Roles
              Indexer → Indexer
              Deployment → Deployment
              Search Head → Search Head + KV Store + License Master
- Install Windows/Linux Addons
```
```
mkdir -p /opt/splunk/etc/deployment-apps/output/local
nano /opt/splunk/etc/deployment-apps/output/local/outputs.conf
```
```
[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = 192.168.1.50:9997

[tcpout-server://192.168.1.50:9997]
```

##### Windows addon
*   Install Splunk Add-on for Microsoft Windows
```
# Copy the 'Splunk_TA_windows' app to the deployment-apps directory.
cp -r /opt/splunk/etc/apps/Splunk_TA_windows /opt/splunk/etc/deployment-apps

# Create the 'local' directory within the 'Splunk_TA_windows' app.
mkdir -p /opt/splunk/etc/deployment-apps/Splunk_TA_windows/local

# Copy the 'inputs.conf' file to the 'local' directory.
cp /opt/splunk/etc/deployment-apps/Splunk_TA_windows/default/inputs.conf /opt/splunk/etc/deployment-apps/Splunk_TA_windows/local/

# Edit the 'inputs.conf' file using the nano editor.
nano /opt/splunk/etc/deployment-apps/Splunk_TA_windows/local/inputs.conf
```
<details>
<summary>Configure event cleanup best practices in props.conf</summary>

Create or navigate to /opt/splunk/etc/deployment-apps/Splunk_TA_windows/local/props.conf
```
[source::WinEventLog:System]
   SEDCMD-clean_info_text_from_winsystem_events_this_event = s/This [Ee]vent is generated[\S\s\r\n]+$//g
   
[source::WinEventLog:Security]
   SEDCMD-windows_security_event_formater = s/(?m)(^\s+[^:]+\:)\s+-?$/\1/g
   SEDCMD-windows_security_event_formater_null_sid_id = s/(?m)(:)(\s+NULL SID)$/\1/g s/(?m)(ID:)(\s+0x0)$/\1/g
   SEDCMD-cleansrcip = s/(Source Network Address:    (\:\:1|127\.0\.0\.1))/Source Network Address:/
   SEDCMD-cleansrcport = s/(Source Port:\s*0)/Source Port:/
   SEDCMD-remove_ffff = s/::ffff://g
   SEDCMD-clean_info_text_from_winsecurity_events_certificate_information = s/Certificate information is only[\S\s\r\n]+$//g
   SEDCMD-clean_info_text_from_winsecurity_events_token_elevation_type = s/Token Elevation Type indicates[\S\s\r\n]+$//g
   SEDCMD-clean_info_text_from_winsecurity_events_this_event = s/This event is generated[\S\s\r\n]+$//g

#For XmlWinEventLog:Security
   SEDCMD-cleanxmlsrcport = s/<Data Name='IpPort'>0<\/Data>/<Data Name='IpPort'><\/Data>/
   SEDCMD-cleanxmlsrcip = s/<Data Name='IpAddress'>(\:\:1|127\.0\.0\.1)<\/Data>/<Data Name='IpAddress'><\/Data>/

[source::WinEventLog:ForwardedEvents]
   SEDCMD-remove_ffff = s/::ffff://g
   SEDCMD-cleansrcipxml = s/<Data Name='IpAddress'>(\:\:1|127\.0\.0\.1)<\/Data>/<Data Name='IpAddress'><\/Data>/
   SEDCMD-cleansrcportxml=s/<Data Name='IpPort'>0<\/Data>/<Data Name='IpPort'><\/Data>/
   SEDCMD-clean_rendering_info_block = s/<RenderingInfo Culture='.*'>(?s)(.*)<\/RenderingInfo>//
   
[WMI:WinEventLog:System]
   SEDCMD-clean_info_text_from_winsystem_events_this_event = s/This event is generated[\S\s\r\n]+$//g
   
[WMI:WinEventLog:Security]
   SEDCMD-windows_security_event_formater = s/(?m)(^\s+[^:]+\:)\s+-?$/\1/g
   SEDCMD-windows_security_event_formater_null_sid_id = s/(?m)(:)(\s+NULL SID)$/\1/g s/(?m)(ID:)(\s+0x0)$/\1/g
   SEDCMD-cleansrcip = s/(Source Network Address:    (\:\:1|127\.0\.0\.1))/Source Network Address:/
   SEDCMD-cleansrcport = s/(Source Port:\s*0)/Source Port:/
   SEDCMD-remove_ffff = s/::ffff://g
   SEDCMD-clean_info_text_from_winsecurity_events_certificate_information = s/Certificate information is only[\S\s\r\n]+$//g
   SEDCMD-clean_info_text_from_winsecurity_events_token_elevation_type = s/Token Elevation Type indicates[\S\s\r\n]+$//g
   SEDCMD-clean_info_text_from_winsecurity_events_this_event = s/This event is generated[\S\s\r\n]+$//g</li>
```
</details>

##### Linux addon
*   Install Splunk Add-on for Unix and Linux
```bash
# Copy the 'Splunk_TA_nix' app to the deployment-apps directory.
cp -r /opt/splunk/etc/apps/Splunk_TA_nix /opt/splunk/etc/deployment-apps

# Create the 'local' directory within the 'Splunk_TA_nix' app.
mkdir -p /opt/splunk/etc/deployment-apps/Splunk_TA_nix/local

# Copy the 'inputs.conf' file to the 'local' directory.
cp /opt/splunk/etc/deployment-apps/Splunk_TA_nix/default/inputs.conf /opt/splunk/etc/deployment-apps/Splunk_TA_nix/local/

# Edit the 'inputs.conf' file using the nano editor.
nano /opt/splunk/etc/deployment-apps/Splunk_TA_nix/local/inputs.conf
```
[Enable data and scripted inputs for the Splunk Add-on for Unix and Linux](https://splunk.github.io/splunk-add-on-for-unix-and-linux/Enabledataandscriptedinputs/)

*    `Settings → Forwarder management → Server Classes`
```
Create:
- Outputs → Clients (*)
- Windows
- Linux
```

```
/opt/splunk/bin/splunk restart
```
Reload the configuration for the Splunk Deployment Server
```
/opt/splunk/bin/splunk reload deploy-server
```

Reloads after installation and restarts client if necessary
```
[serverClass:<Class Name>]
issueReload=true
restartIfNeeded=true
```
</details>

<details>
<summary><b>SearchHead Server</b></summary>

```
- Settings → Licensing
- Install/Hide Apps & Addons
- Settings → Distributed search → Search peers (Indexers + Search heads)
```
</details>

<details>
<summary><b>Install/Update an app or add-on</b></summary>

```
/opt/splunk/bin/splunk install app <app.spl/tgz>
/opt/splunk/bin/splunk install app <app.spl/tgz> -update 1
```
</details>


<details>
<summary><b>Reset Splunk Admin Password</b></summary>
  
```
- Stop Splunk:
  $SPLUNK_HOME/bin/splunk stop

- Backup passwd file:
  mv $SPLUNK_HOME/etc/passwd $SPLUNK_HOME/etc/passwd.bk

- Create user-seed.conf:
  Path: $SPLUNK_HOME/etc/system/local/user-seed.conf

- Add content:
  [user_info]
  PASSWORD = NEW_PASSWORD

- Start Splunk:
  $SPLUNK_HOME/bin/splunk start

- Login:
  Username: admin
  Password: NEW_PASSWORD

- (Optional) Restore users:
  Copy from $SPLUNK_HOME/etc/passwd.bk to $SPLUNK_HOME/etc/passwd
  Then restart:
  $SPLUNK_HOME/bin/splunk restart

- Notes:
  user-seed.conf works only if passwd is missing
  chown splunk:splunk $SPLUNK_HOME/etc/system/local/user-seed.conf
  Remove user-seed.conf after login
```
</details>

<details>
<summary><b>Troubleshoot</b></summary>

```
#######  Searches Skipped in the last 24 hours  #######
Settings -> Monitoring Console -> Search -> Scheduler Activity: Instance, and inputing the timeframe when this occurred.

#######  License  #######
# Lists the current licenses installed and activated on your Splunk instance.
/opt/splunk/bin/splunk list license

# Remove a specific license from the Splunk instance, identified by the license hash.
/opt/splunk/bin/splunk remove license <hash>

# Troubleshoot license
/opt/splunk/bin/splunk btool server list --debug license

#######  A storage location for logs  #######
cd /opt/splunk/var/lib/splunk

#######  Troubleshoot  #######
# Btool command:
/opt/splunk/bin/splunk btool <conf_file_prefix> [list|layer|add|delete] --debug --app=<app_name> --user=<user_name>

# Btool check command to find typos in conf file stanzas:
/opt/splunk/bin/splunk btool check

# To reset fishbucket for all sources, must execute with caution:
/opt/splunk/bin/splunk clean eventdata index _thefishbucket

# Troubleshoot configurations
/opt/splunk/bin/splunk btool check --debug

# Verify Splunk's integrity
/opt/splunk/bin/splunk validate files

# Troubleshoot your tailed files
curl https://serverhost:8089/services/admin/inputstatus/TailingProcessor:FileStatus

# Header options
nano /opt/splunk/etc/system/local/web.conf

[settings]
x_frame_options_sameorigin = true
replyHeader.X-Frame-Options = SAMEORIGIN

#######  RPM  #######
sudo rm -rf /var/lib/rpm/__db*
rpm --rebuilddb
sudo rpm -i --nosignature <package>
mv /etc/init.d /etc/init.d.bak
```
</details>

<details>
<summary><b>Resources</b></summary>

***Splunk Enterprise 10.2***

- [Administer the app key value store](https://help.splunk.com/en/splunk-enterprise/administer/admin-manual/10.2/administer-the-app-key-value-store/about-the-app-key-value-store)
- [Manage apps and add-ons on standalone instances](https://help.splunk.com/en/splunk-enterprise/administer/admin-manual/10.2/meet-splunk-apps/manage-app-and-add-on-objects#ariaid-title4)
- [How to upgrade Splunk Enterprise](https://help.splunk.com/en/splunk-enterprise/get-started/install-and-upgrade/10.2/upgrade-or-migrate-splunk-enterprise/how-to-upgrade-splunk-enterprise)
- [Uninstall Splunk Enterprise](https://help.splunk.com/en/splunk-enterprise/get-started/install-and-upgrade/10.2/uninstall-splunk-enterprise/uninstall-splunk-enterprise)
- [Types of Distributed Deployments](https://help.splunk.com/en/splunk-enterprise/administer/distributed-deployment-manual/10.2/implement-a-distributed-deployment/types-of-distributed-deployments)
- [Reference hardware](https://help.splunk.com/en/splunk-enterprise/get-started/deployment-capacity-manual/10.2/performance-reference/reference-hardware)
- [Supported Operating Systems](https://help.splunk.com/en/splunk-enterprise/get-started/install-and-upgrade/10.2/plan-your-splunk-enterprise-installation/system-requirements-for-use-of-splunk-enterprise-on-premises#ariaid-title2)
- [Which instance should host the console?](https://help.splunk.com/en/splunk-enterprise/administer/monitor/10.2/configure-the-monitoring-console/which-instance-should-host-the-console)
- [Splunk products version compatibility matrix](https://help.splunk.com/en/splunk-enterprise/release-notes-and-updates/compatibility-matrix/splunk-products-version-compatibility/splunk-products-version-compatibility-matrix)
- [Compatibility between forwarders and Splunk Enterprise indexers](https://help.splunk.com/en/splunk-enterprise/release-notes-and-updates/compatibility-matrix/splunk-products-version-compatibility/compatibility-between-forwarders-and-splunk-enterprise-indexers)
- [Migrate a Splunk Enterprise instance from one physical machine to another](https://help.splunk.com/en/splunk-enterprise/get-started/install-and-upgrade/10.2/upgrade-or-migrate-splunk-enterprise/migrate-a-splunk-enterprise-instance-from-one-physical-machine-to-another)
- [Anonymize data](https://help.splunk.com/en/splunk-enterprise/get-started/get-data-in/10.2/configure-event-processing/anonymize-data)
- [Monitor changes to your file system](https://help.splunk.com/en/splunk-enterprise/get-started/get-data-in/10.2/get-other-kinds-of-data-in/monitor-changes-to-your-file-system)
- [HTTP Event Collector examples](https://help.splunk.com/en/splunk-enterprise/get-started/get-data-in/10.2/get-data-with-http-event-collector/http-event-collector-examples)

***Splunk ES v8.5***
- [Minimum specifications for a production deployment](https://help.splunk.com/en/splunk-enterprise-security-8/install/8.5/planning/minimum-specifications-for-a-production-deployment)

</details>



