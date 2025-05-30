<details>
<summary><b>Preparing a System Before Splunk Installation</b></summary>
  
<details>
<summary><b>Update the system & Install additional tools</b></summary>

RHEL family
```
yum update -y
yum install -y dnf
dnf install -y net-tools nano bind-utils chkconfig wget net-tools tcpdump fio bzip2 sysstat elfutils polkit.x86_64 telnet cloud-utils-growpart
```
Debian family
```
apt update -y
apt full-upgrade -y
apt install -y net-tools nano wget net-tools tcpdump screen iotop htop ioping fio bzip2 sysstat elfutils telnet cloud-guest-utils
```
</details>

<details>
<summary><b>Change Timezone</b></summary>

```
timedatectl
timedatectl set-timezone Asia/Jerusalem
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

*   `ip a`
*   `vi /etc/sysconfig/network-scripts/ifcfg-<int>`
  
```
ONBOOT=yes
IPADDR=<IP>                                       *****
PREFIX=                                           *****
GATEWAY=<GW>                                      *****
DNS1=<DNS1>                                       *****
DNS2=<DNS2>                                       *****
```
*   `systemctl restart network.service`
</details>

<details>
<summary><b>Change NTP Server</b></summary>

#### chronyd
```
# Verfiy
timedatectl
chronyc sources

# Configuration
nano /etc/chrony.conf

# Service
systemctl status chronyd
systemctl start chronyd
systemctl enable chronyd
```

#### NTP
```
dnf install ntp
systemctl start ntp
systemctl enable ntp
```

*   `nano /etc/ntp.conf`

*   server "IP Address"
  
```
systemctl restart ntpd
ntpq -p
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

Default Linux kernel settings are not sufficient for high-volume packet capture. Using these settings can cause missing packets and data loss. To avoid this issue, add the following kernel settings to your `/etc/sysctl.conf` file:
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

```diff
- After completing the above, restart the system
reboot
```
</details>

<details>
<summary><b>Splunk Enterprise (Linux)</b></summary>

```
# Install Splunk using RPM:
rpm -ivh --force --nosignature splunk_package_name.rpm

# Install Splunk using Tar:
tar xvzf splunk_package_name.tgz -C /opt

# Enable Splunk to start on boot (Initd) and accept the license:
/opt/splunk/bin/splunk enable boot-start -user splunk --accept-license

# Enable Splunk to start on boot (Systemd) and accept the license:
/opt/splunk/bin/splunk enable boot-start -systemd-managed 1 -user splunk --accept-license
```

Change servername & hostname
```
/opt/splunk/bin/splunk set servername host.domain.com
/opt/splunk/bin/splunk set default-hostname host.domain.com
```
</details>

<details>
<summary><b>Splunkd.service (Systemd)</b></summary>

[Configure Linux systems running systemd (Splunk v9.4.0)](https://docs.splunk.com/Documentation/Splunk/9.4.0/Workloads/Configuresystemd)

[Enable workload management (Splunk v9.4.0)](https://docs.splunk.com/Documentation/Splunk/9.4.0/Workloads/Enableworkloadmanagement)

Path: `nano /etc/systemd/system/Splunkd.service`

Add or change the values in the file. Example:
```
LimitDATA=20000000000
LimitFSIZE=infinity
TasksMax=8192
```

```
systemctl daemon-reload
```
Cgroup Version
```
# Checking cgroup Version via `/proc/filesystems`
grep cgroup /proc/filesystems

# Output Interpretation
# Systems Supporting cgroupv2
nodev   cgroup
nodev   cgroup2

# Systems with cgroupv1 Only
nodev   cgroup
```
</details>

<details>
<summary><b>Enable SSL</b></summary>
  
*   `nano /opt/splunk/etc/system/local/web.conf`
```text-plain
[settings]
max_upload_size = 2048
enableSplunkWebSSL = true
splunkdConnectionTimeout = 3000
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
max_mem_usage_mb = 12288

[searchresults]
maxresultrows = 200000

# The maximum number of concurrent historical searches in the search head.
total_search_concurrency_limit = auto

# The base number of concurrent historical searches.
base_max_searches = 8

# Max real-time searches = max_rt_search_multiplier x max historical searches.
max_rt_search_multiplier = 3

# The maximum number of concurrent historical searches per CPU.
max_searches_per_cpu = 16

[scheduler]
# The maximum number of searches the scheduler can run, as a percentage
# of the maximum number of concurrent searches.
max_searches_perc  = 75

# Fraction of concurrent scheduler searches to use for auto summarization.
auto_summary_perc  = 75
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
# 1
```
/opt/splunk/bin/splunk disable webserver
```
# 2
```
sudo nano /opt/splunk/etc/system/local/web.conf
```
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
<summary><b>Upgrade Splunk Enterprise (Linux)</b></summary>
  
- [How to upgrade Splunk Enterprise](https://docs.splunk.com/Documentation/Splunk/latest/Installation/HowtoupgradeSplunk)
- [Splunk products version compatibility matrix](https://docs.splunk.com/Documentation/VersionCompatibility/latest/Matrix/CompatMatrix)
- [Compatibility between forwarders and Splunk Enterprise indexers](https://docs.splunk.com/Documentation/VersionCompatibility/latest/Matrix/Compatibilitybetweenforwardersandindexers)

```
# Stop Splunk
/opt/splunk/bin/splunk stop

# Upgrade Splunk using RPM
rpm -Uvh <Package>

# Check the status of Splunk
/opt/splunk/bin/splunk status

# Accept the license
<q> <y> <y>

# Change the ownership of the splunk directory.
chown -R splunk:splunk /opt/splunk

# Start Splunk
/opt/splunk/bin/splunk start
```
</details>

<details>
<summary><b>Uninstall Splunk Enterprise (Linux)</b></summary>

```
# Stop Splunk
/opt/splunk/bin/splunk stop

# Uninstall Splunk using RPM:
rpm -e `rpm -qa | grep -i splunk`

# Remove the Splunk installation directory:
sudo rm -r /opt/splunk

# Delete the splunk user and group, if they exist.
userdel splunk
groupdel splunk
```
</details>
 
<details>
<summary><b>Uninstall an app or add-on</b></summary>

- Delete the app and its directory. The app and its directory are typically located in `$SPLUNK_HOME/etc/apps/<appname>`.
- You may need to remove user-specific directories created for your app or add-on by deleting any files found here: `$SPLUNK_HOME/etc/users/*/<appname>`.
</details>

<details>
<summary><b>Splunk Admin Password Reset</b></summary>
  
```
# Stop Splunk Service
/opt/splunk/bin/splunk stop

# Move Existing Passwd File to Backup Location
mv /opt/splunk/etc/passwd /opt/splunk/etc/passwd.bkp

# Generate Password Hash
/opt/splunk/bin/splunk hash-passwd 'your-new-password'

# Create User-Seed.Conf File
nano /opt/splunk/etc/system/local/user-seed.conf
```
Containing the username and password (or password hash) you want to use:
```
[user_info]
USERNAME = admin
HASHED_PASSWORD = myPassword
```
Restart Splunk
```
/opt/splunk/bin/splunk restart
```
##### Log In with New Password
After the restart, a new `passwd` file will be generated, and you should be able to log in successfully with your new password. 
</details>

<details>
<summary><b>Troubleshoot & Others</b></summary>

```
#######  License  #######
# Lists the current licenses installed and activated on your Splunk instance.
/opt/splunk/bin/splunk list license

# Remove a specific license from the Splunk instance, identified by the license hash.
/opt/splunk/bin/splunk remove license <hash>

#######  A storage location for logs  #######
cd /opt/splunk/var/lib/splunk

#######  Troubleshoot  #######
# Btool command:
/opt/splunk/bin/splunk btool <conf_file_prefix> [list|layer|add|delete] --debug --app=<app_name> --user=<user_name>

# Btool check command to find typos in conf file stanzas:
/opt/splunk/bin/splunk btool check

# To reset fishbucket for all sources, must execute with caution:
/opt/splunk/bin/splunk clean eventdata index _thefishbucket

# Check Splunk Version
/opt/splunk/bin/splunk -version

# Troubleshoot configurations
/opt/splunk/bin/splunk btool check --debug

# Verify Splunk's integrity
/opt/splunk/bin/splunk validate files

# PostgreSQL binaries are located in
/opt/splunk/bin/

# Troubleshoot license
/opt/splunk/bin/splunk btool server list --debug license

# Files
/opt/splunk/var/log/splunk/splunkd.log
/opt/splunk/var/log/splunk/splunkd_access.log
/opt/splunk/var/log/splunk/splunkd_ui_access.log

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
<summary><b>Kvstore</b></summary>

```
# Path
/var/lib/splunk/kvstore/mongo

# Status
/opt/splunk/bin/splunk show kvstore-status --verbose

# Clean
/opt/splunk/bin/splunk clean kvstore -local

# Migrate
/opt/splunk/bin/splunk stop
sudo rm /opt/splunk/var/run/splunk/kvstore_upgrade/*
touch /opt/splunk/var/run/splunk/kvstore_upgrade/versionFile36
/opt/splunk/bin/splunk migrate kvstore-storage-engine --target-engine wiredTiger --enable-compression
/opt/splunk/bin/splunk migrate migrate-kvstore # (1) - versionFile40
/opt/splunk/bin/splunk migrate migrate-kvstore # (2) - versionFile42
/opt/splunk/bin/splunk start
/opt/splunk/bin/splunk show kvstore-status --verbose

# KV Store Process Terminated
### 1
/opt/splunk/bin/splunk stop
sudo rm /opt/splunk/var/lib/splunk/kvstore/mongo/mongod.lock
/opt/splunk/bin/splunk start
### 2
/opt/splunk/bin/splunk stop
mv /opt/splunk/var/lib/splunk/kvstore/mongo /opt/splunk/var/lib/splunk/kvstore/mongo.old
/opt/splunk/bin/splunk start
### 3 
/opt/splunk/bin/splunk stop
chmod 700 /opt/splunk/var/lib/splunk/kvstore/mongo/splunk.key
/opt/splunk/bin/splunk start
```
</details>

<details>
<summary><b>HEC_API_cURL_examples</b></summary>

Sending data as a JSON formatted payload – collector/event request. Make sure to replace with active HEC token and splunk host
```
curl –k -H "Authorization: Splunk 09776ade-cf23-42c0-9138-89ad8388516a" -H "X-Splunk-Request-Channel: FE0ECFAD-13D5-401B-847D-77833BD77131" https://mysplunk.example.com:8088/services/collector/event -d '{"sourcetype": "signaling_data", "event": "stable signal!"}'
```
Sending data as a raw event – Collector/raw request:
```
curl –k -H "Authorization: Splunk 09776ade-cf23-42c0-9138-89ad8388516a" -H "X-Splunk-Request-Channel: FE0ECFAD-13D5-401B-847D-77833BD77131" https://mysplunk.example.com:8088/services/collector/raw -d 'stable signal!'
```
Finding the event indexing status – /ack endpoint request
```
curl -H "Authorization: Splunk 09776ade-cf23-42c0-9138-89ad8388516a" -H "X-Splunk-Request-Channel: FE0ECFAD-13D5-401B-847D-77833BD77131" https://mysplunk.example.com:8088/services/collector/ack -d '{"acks":[0,1]}'
```
</details>

<details>
<summary><b>Migrate a Splunk Enterprise instance</b></summary>

**How to migrate**

When you migrate on *nix systems, you can extract the tar file you downloaded directly over the copied files on the new system, or use your package manager to upgrade using the downloaded package. On Windows systems, the installer updates the Splunk files automatically.
1. Stop Splunk Enterprise services on the host from which you want to migrate.
2. Copy the entire contents of the $SPLUNK_HOME directory from the old host to the new host. Copying this directory also copies the mongo subdirectory.
3. Install Splunk Enterprise on the new host.
4. Verify that the index configuration (indexes.conf) file's volume, sizing, and path settings are still valid on the new host.
5. Start Splunk Enterprise on the new instance.
6. Log into Splunk Enterprise with your existing credentials.
7. After you log in, confirm that your data is intact by searching it.
</details>

<details>
<summary><b>Custom Configuration</b></summary>

**Anonymize data**

Prerequisites to [anonymize data](https://docs.splunk.com/Documentation/Splunk/latest/Data/Anonymizedata)
Before you can anonymize data, you must select a set of events to anonymize.

- First, you select the events to anonymize
- Then, you either:
    - Use the props.conf configuration file to anonymize the events with a sed script
    - Use the props.conf and transforms.conf configuration files to anonymize the events with a regular expression transform
 
```
SEDCMD-maskCC = s/-\d{4}-\d{4}-\d{4}/-XXXX-XXXX-XXXX/g
```

[**Monitor changes to your file system**](https://docs.splunk.com/Documentation/Splunk/latest/Data/Monitorchangestoyourfilesystem)
```
[fschange:/opt/test]
index = fschange
recurse = true
pollPeriod = 10
signedaudit = false
fullEvent = true
sendEventMaxSize = 1048576
crcSalt = <SOURCE>
sourcetype = fs_notification
```
</details>

<details>
<summary><b>Splunk Checklist</b></summary>

-   Splunk Side
    -   Upgrade/Update Version of:
        -   Splunk Enterprise & Universal Forwarder
        -   Splunk Enterprise Security & Splunk ES Content Update
        -   Splunk Apps & Add-ons
    -   License Usage
    -   Specs of Splunk Servers
    -   Health Check Assessment
    -   Configure Retention Period
    -   Best Practices
        -   Splunk Deployment
        -   Splunk Configuration
        -   Apps & Add-ons Deployment
    -   Configure Email Settings (Server Settings)
    -   Configure Alerts Setup (MC)
    -   Start on Boot
    -   Enable SSL (HTTPS)
    -   Forwarding Splunk's internal logs to the indexers
    -   Preferences (Global & SPL Editor)
-   Server Side
    -   Hostname
    -   NTP
    -   Timezone
    -   DNS
    -   Ulimits
    -   Disable SELinux
    -   Disable Host-Based Firewall (Firewalld)
    -   Disable Transparent Huge Pages (THP)
</details>
