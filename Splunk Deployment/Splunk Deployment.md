<details>
<summary><b>CentOS</b></summary>
  
##### Downloading
https://docs.centos.org/en-US/centos/install-guide/downloading/
##### Quick Installation Guide
https://docs.centos.org/en-US/centos/install-guide/Simple_Installation/
##### Migration directions
[Link](https://wiki.almalinux.org/elevate/ELevate-quickstart-guide.html)


<img src="https://github.com/MrM8BRH/Splunk/assets/34133187/c55f2252-c151-4ed7-83b9-c0bbe6fc07c5">
</details>

<details>
<summary><b>Distributed Deployment</b></summary>
  
[Types of distributed deployments](https://docs.splunk.com/Documentation/Splunk/latest/Deploy/Deploymentcharacteristics)
- Departmental. A single instance that combines indexing and search management functions.
- [Small enterprise.](https://docs.splunk.com/Documentation/Splunk/latest/Deploy/Searchheadwithindexers) One search head with two or three indexers.
- Medium enterprise. A small search head cluster, with several indexers.
- Large enterprise. A large search head cluster, with large numbers of indexers.

[Which instance should host the console?](https://docs.splunk.com/Documentation/Splunk/latest/DMC/WheretohostDMC)

[Implement a deployment server cluster](https://docs.splunk.com/Documentation/Splunk/latest/Updating/Implementascalabledeploymentserversolution)

</details>

<details>
<summary><b>Preparing a System Before Splunk Installation</b></summary>
  
<details>
<summary><b>Update the system & Install additional tools</b></summary>

RHEL family
```
yum update -y
yum install -y dnf
dnf install -y net-tools nano bind-utils chkconfig wget net-tools tcpdump fio bzip2 sysstat elfutils polkit.x86_64 telnet
```
Debian family
```
apt update -y
apt full-upgrade -y
apt install -y net-tools nano wget net-tools tcpdump screen iotop htop ioping fio bzip2 sysstat elfutils telnet
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

```
# Check the current status and mode of SELinux.
sestatus

# Opens the SELinux configuration file using the nano text editor.
nano /etc/selinux/config

# A configuration option that can be set in the SELinux configuration file to disable SELinux on the system,
# preventing it from enforcing security policies.
SELINUX=disabled
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
rpm -ivh splunk_package_name.rpm

# Install Splunk using Tar:
tar xvzf splunk_package_name.tgz -C /opt

# Enable Splunk to start on boot (Initd) and accept the license:
/opt/splunk/bin/splunk enable boot-start -user splunk --accept-license

# Enable Splunk to start on boot (Systemd) and accept the license:
/opt/splunk/bin/splunk enable boot-start -systemd-managed 1 -create-polkit-rules 1 -user splunk --accept-license

chown -R splunk /opt/splunk
```
</details>

<details>
<summary><b>Splunkd.service (Systemd)</b></summary>
  
`nano /etc/systemd/system/Splunkd.service`

For cgroups v1:
```
[Unit]
After=network.target

[Service]
Type=simple
Restart=always
ExecStart=/opt/splunk/bin/splunk _internal_launch_under_systemd
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=360
LimitNOFILE=65536
SuccessExitStatus=51 52
RestartPreventExitStatus=51
RestartForceExitStatus=52
User=splunk
Group=splunk
Delegate=true
CPUShares=1024
MemoryLimit=32G
PermissionsStartOnly=true
ExecStartPost=/bin/bash -c "chown -R splunk:splunk /sys/fs/cgroup/cpu/system.slice/%n"
ExecStartPost=/bin/bash -c "chown -R splunk:splunk /sys/fs/cgroup/memory/system.slice/%n"

[Install]
WantedBy=multi-user.target
```
For cgroups v2:
```
#This unit file replaces the traditional start-up script for systemd
#configurations, and is used when enabling boot-start for Splunk on
#systemd-based Linux distributions.

[Unit]
Description=Systemd service file for Splunk, generated by 'splunk enable boot-start'
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Restart=always
ExecStart=/opt/splunk/bin/splunk _internal_launch_under_systemd
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=360
LimitNOFILE=65536
LimitRTPRIO=99
SuccessExitStatus=51 52
RestartPreventExitStatus=51
RestartForceExitStatus=52
User=splunk
Group=splunk
Delegate=true
CPUWeight=100
MemoryMax=<total_available_system_memory>
PermissionsStartOnly=true
ExecStartPost=-/bin/bash -c "chown -R splunk:splunk /sys/fs/cgroup/system.slice/%n"

[Install]
WantedBy=multi-user.target
```
[Configure Linux systems running systemd (Splunk v9.4.0)](https://docs.splunk.com/Documentation/Splunk/9.4.0/Workloads/Configuresystemd)

[Set limits using the /etc/systemd configuration files](https://docs.splunk.com/Documentation/Splunk/latest/Troubleshooting/ulimitErrors#Set_limits_using_the_.2Fetc.2Fsystemd_configuration_files)

Add or change the values in the file. Example:
```
LimitNOFILE=65536
LimitNPROC=16000
LimitDATA=8589934592
LimitFSIZE=infinity
TasksMax=8192
```

```
systemctl daemon-reload
```

![image](https://github.com/user-attachments/assets/41f8d0af-bc3d-4b95-b751-76fc99db3361)
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
  
In the [limits.conf](https://docs.splunk.com/Documentation/Splunk/latest/Admin/Limitsconf) file, consider reviewing and adjusting the following settings to optimize Splunk performance:
*   `nano /opt/splunk/etc/system/local/limits.conf`
```
############################################################################
# GLOBAL SETTINGS
############################################################################
[default]
max_mem_usage_mb = 12288

[searchresults]
maxresultrows = 200000

############################################################################
# Concurrency
############################################################################
# The maximum number of concurrent historical searches in the search head.
total_search_concurrency_limit = auto

# The base number of concurrent historical searches.
base_max_searches = 8

# Max real-time searches = max_rt_search_multiplier x max historical searches.
max_rt_search_multiplier = 3

# The maximum number of concurrent historical searches per CPU.
max_searches_per_cpu = 16


############################################################################
# GENERAL
############################################################################
# This section contains the stanzas for a variety of general settings.

[scheduler]
# The maximum number of searches the scheduler can run, as a percentage
# of the maximum number of concurrent searches.
max_searches_perc  = 75

# Fraction of concurrent scheduler searches to use for auto summarization.
auto_summary_perc  = 75
```
These adjustments should be aligned with our system requirements and available resources.

nano /opt/splunk/etc/system/local/server.conf
```
[general]
conf_cache_memory_optimization = true
sessionTimeout = 8h
```

Change servername
```
/opt/splunk/bin/splunk set servername host.domain.com
/opt/splunk/bin/splunk set default-hostname host.domain.com
```
</details>
  
<details>
<summary><b>Forwarding Splunk's internal logs to the indexers</b></summary>

*    `nano /opt/splunk/etc/system/local/outputs.conf`
```
# Turn off indexing
[indexAndForward]
index = false

[tcpout] defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = 192.168.1.50:9997

[tcpout-server://192.168.1.50:9997]
```
</details>

<details>
<summary><b>Indexer Server</b></summary>

```
- Settings -> Forwarding and reciving -> Configure receiving
- Settings -> Licensing -> (Change to peer [deployment server])
- Settings -> Indexes - Add indexes like: wineventlog, linux, fortigate, crowdstrike, pam, f5, oracle, mysql .. etc
- Apps -> Manage Apps -> Disable (Monitoring Console)
- Install Addons
- Disable Splunk Web
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

`nano /opt/splunk/etc/system/local/indexes.conf`
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

[Archive indexed data](https://docs.splunk.com/Documentation/Splunk/9.3.1/Indexer/Automatearchiving)

[coldtofrozenscriptexample.py](https://community.splunk.com/t5/Getting-Data-In/Does-anyone-have-a-working-example-of-coldtofrozenscript-py/m-p/213023/highlight/true#M41862)

</details>

<details>
<summary><b>Deployment Server</b></summary>

```
- Settings -> Licensing -> (Change license group)
- Settings -> Server settings -> Email settings
- Settings -> Distributed search -> Search peers (Indexers + Search heads)
- Settings -> Monitoring Console -> Settings -> Alerts Setup
- Settings -> Monitoring Console -> Settings -> Forwarder Monitoring Setup
- Settings -> Monitoring Console -> Forwarders -> forwarder_instance
- Settings -> Monitoring Console -> Settings -> General Setup [Standalone -> Distributed]
   Edit Roles
              Indexer -> Indexer
              Deployment -> Deployment + + KV Store + License Master
              Search Head -> Search Head + KV Store
- Install Windows/Linux Addons
```
```
- mkdir -p /opt/splunk/etc/deployment-apps/output/local
- cd /opt/splunk/etc/deployment-apps/output/local
- nano outputs.conf
```
```
# Turn off indexing
[indexAndForward]
index = false

[tcpout] defaultGroup = default-autolb-group

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

Create or navigate to /opt/splunk/etc/apps/Splunk_TA_windows/local/props.conf
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
*    `Settings -> Forwarder management -> Server Classes`
```
Create:
- output -> Clients (*)
- windows
- linux
```

```
/opt/splunk/bin/splunk restart
```
Reload the configuration for the Splunk Deployment Server
```
/opt/splunk/bin/splunk reload deploy-server
```
List Deployment Clients
```
/opt/splunk/bin/splunk btool deploymentclient list deployment-client 
```

</details>

<details>
<summary><b>SearchHead Server</b></summary>

```
- Settings -> Licensing -> (Change to peer [deployment server])
- Install/Hide Apps & Addons (Apps -> Manage Apps)
- Settings -> Distributed search -> Search peers (Indexers + Search heads)
- Apps -> Search & Reporting ->  Data Summary
- Apps -> Manage Apps -> Disable (Monitoring Console)
- Activity -> Jobs
```
</details>

<details>
<summary><b>Upgrade Splunk Enterprise (Linux)</b></summary>
  
[How to upgrade Splunk Enterprise](https://docs.splunk.com/Documentation/Splunk/latest/Installation/HowtoupgradeSplunk)

[Splunk products version compatibility matrix](https://docs.splunk.com/Documentation/VersionCompatibility/latest/Matrix/CompatMatrix)

[Compatibility between forwarders and Splunk Enterprise indexers](https://docs.splunk.com/Documentation/VersionCompatibility/latest/Matrix/Compatibilitybetweenforwardersandindexers)
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

Mass deployment (Upgrade)
- Windows OS
```
Stop-Service SplunkForwarder
msiexec.exe /i splunkuniversalforwarder_x64.msi AGREETOLICENSE=Yes /quiet
```
- Linux OS
```
/opt/splunkforwarder/bin/splunk stop
useradd splunkfwd
rpm -Uvh splunkuniversalforwarder_x64.rpm
/opt/splunkforwarder/bin/splunk disable boot-start
/opt/splunkforwarder/bin/splunk enable boot-start --accept-license --no-prompt --answer-yes
/opt/splunkforwarder/bin/splunk start
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
<summary><b>Disable Splunk Web</b></summary>
  
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

#######  Kvstore  #######
# Path
/var/lib/splunk/kvstore/mongo

# Status
/opt/splunk/bin/splunk show kvstore-status

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

#######  Troubleshoot  #######
# Check Splunk Version
/opt/splunk/bin/splunk -version

# Troubleshoot configurations
/opt/splunk/bin/splunk btool check --debug
# Troubleshoot license
/opt/splunk/bin/splunk btool server list --debug license

# Files
/opt/splunk/var/log/splunk/splunkd.log
/opt/splunk/var/log/splunk/splunkd_access.log
/opt/splunk/var/log/splunk/splunkd_ui_access.log

# Troubleshoot your tailed files
curl https://serverhost:8089/services/admin/inputstatus/TailingProcessor:FileStatus

# Increase the session timeout settings
1. nano /opt/splunk/etc/system/local/server.conf
[general]
sessionTimeout = 3h
2. nano /opt/splunk/etc/system/local/web.conf
[settings] 
tools.sessions.timeout = 180

# JAVA for DB Connect app
PATH: /opt/splunk/etc/apps/splunk_app_db_connect/linux_x86
URL: https://www.oracle.com/java/technologies/javase/jdk11-archive-downloads.html
Permission: chown -R splunk:splunk /opt/splunk

# Header options
nano /opt/splunk/etc/system/local/web.conf

[settings]
x_frame_options_sameorigin = true
replyHeader.X-Frame-Options = SAMEORIGIN


# Missing Forwarders
https://community.splunk.com/t5/Getting-Data-In/monitoring-console-triggered-alerts-missing-forwarders-but-they/m-p/458517
https://community.splunk.com/t5/Getting-Data-In/What-does-the-heartbeatFrequency-setting-do-in-outputs-conf/m-p/267281
```
</details>

<details>
<summary><b>Splunk Health Check & Best Practices</b></summary>

- Perform Health Check Assessment using monitoring console.
- Optimize ulimits and other parameters based on Splunk documentation and your environment.
- Monitor /opt storage space and consider expansion if needed.
- Increase system resources if needed.
- Assess index sizes and usage on indexer server, optimize as required.
- Review and adjust log verbosity and frequency based on your needs.
- Check Activity for running or queued jobs impacting performance.
- Host Console Monitoring and License Manager on deployment server/manager node.
- Check Splunk ES configuration.
- Disable host-based Firewall and SElinux.
- Disable Transparent Huge Pages.
- Remove Apps and addons that not be used.
- Enable Systemd for Splunk service for better management and stability.
- limits.conf & props.conf: Verify and optimize configurations for performance and tuning gains.
- [Reducing skipped searches](https://lantern.splunk.com/Splunk_Platform/Product_Tips/Searching_and_Reporting/Reducing_skipped_searches)

It's a best practice to disable KV-Store in all Splunk servers except Search Heads to use the resources for other purposes,

even if, there are some Add-Ons, that must be installed on HFs or IDXs, that disabling KV-Store will give you error messages because they use KV-Store .

Anyway, you can disable KV-Store adding to server.conf the following stanza:
```
[kvstore]
disabled = true
```

Data Model Best practices
- Every accelerated data model should have specific indexes defined. 
- Only enable acceleration for data models that are applicable for your environment. If you don’t have data sources for a specific data model, disable acceleration. 
- Consider disabling acceleration for data models that are not powering correlation searches, especially if you’re not planning to use this data for security use cases in the future. 
- Regularly review the data in your Splunk environment and update the index constraints as new data sources are added. Include updating these constraints as part of your data onboarding processes. 

</details>
