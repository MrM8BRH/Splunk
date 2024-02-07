## CentOS
### Downloading
https://docs.centos.org/en-US/centos/install-guide/downloading/
### Quick Installation Guide
https://docs.centos.org/en-US/centos/install-guide/Simple_Installation/

## Preparing a System Before Splunk Installation

<details>
<summary><h3>Update the system & Install additional tools</h3></summary>

```
yum update -y
yum install -y dnf
dnf install -y net-tools nano bind-utils chkconfig wget net-tools tcpdump screen iotop htop ioping fio bzip2
```
</details>

<details>
<summary><h3>Change Timezone</h3></summary>

```
timedatectl
timedatectl set-timezone Asia/Jerusalem
```
</details>

<details>
<summary><h3>Change Hostname</h3></summary>

```
hostnamectl
hostnamectl set-hostname <hostname>
```
</details>

<details>
<summary><h3>Change IP Address, DNS Server, Gateway</h3></summary>

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
<summary><h3>Change NTP Server</h3></summary>

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
<summary><h3>Disable SELinux</h3></summary>

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
<summary><h3>Disable Firewall</h3></summary>

```
systemctl stop firewalld
systemctl disable firewalld
```
</details>


<details>
<summary><h3>Disable Transparent Huge Pages (THP)</h3></summary>

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

## Splunk Enterprise (Linux)
```
# Install Splunk using RPM:
rpm -ivh splunk_package_name.rpm

# Install Splunk using Tar:
tar xvzf splunk_package_name.tgz -C /opt

# Enable Splunk to start on boot and accept the license:
/opt/splunk/bin/splunk enable boot-start -systemd-managed 1 -user splunk -group splunk --accept-license
```

### Splunkd.service
`nano /etc/systemd/system/Splunkd.service`

Add or change the values in the file:
```
LimitNOFILE=64000
LimitNPROC=16000
LimitDATA=20000000000
LimitFSIZE=infinity
TasksMax=8192
```
[Set limits using the /etc/systemd configuration files](https://docs.splunk.com/Documentation/Splunk/latest/Troubleshooting/ulimitErrors#Set_limits_using_the_.2Fetc.2Fsystemd_configuration_files)
```
systemctl daemon-reload
```

### Enable SSL
*   `nano /opt/splunk/etc/system/local/web.conf`
```text-plain
[settings]
max_upload_size = 2048
enableSplunkWebSSL = true
splunkdConnectionTimeout = 3000
```

### Optimization Recommendations
In the [limits.conf](https://docs.splunk.com/Documentation/Splunk/latest/Admin/Limitsconf) file, consider reviewing and adjusting the following settings to optimize Splunk performance:
*   `nano /opt/splunk/etc/system/local/limits.conf`
```
[default]
max_mem_usage_mb = 8192

[search]
base_max_searches = 6
max_searches_per_cpu = 16
max_rt_search_multiplier = 3

[mvcombine]
max_mem_usage_mb = 1024

[mvexpand]
max_mem_usage_mb = 1024

[sort]
maxfiles = 128
```
These adjustments should be aligned with our system requirements and available resources.

### Start and enable Splunk service
- `systemctl start Splunkd.service`
- `systemctl enable Splunkd.service`

### Forwarding Splunk's internal logs to the indexers
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

## Indexer Server
```
- Settings -> Forwarding and reciving -> Configure receiving
- Settings -> Licensing -> (Change to peer [deployment server])
- Settings -> Monitoring Console -> Settings -> General Setup [Standalone -> Distributed]
- Settings -> Indexes - Add indexes like: wineventlog, linux, fortigate, crowdstrike, pam, f5, oracle, mysql .. etc
- Apps -> Manage Apps -> Disable (Monitoring Console)
- Install Addons
- Disable Splunk Web
```

### Log Retention

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


## Deployment Server
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

#### Windows addon
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

#### Linux addon
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

## SearchHead Server
```
- Settings -> Licensing -> (Change to peer [deployment server])
- Install/Hide Apps & Addons (Apps -> Manage Apps)
- Apps -> Search & Reporting ->  Data Summary
- Settings -> Distributed search -> Search peers (Indexers + Search heads)
- Apps -> Manage Apps -> Disable (Monitoring Console)
- Activity -> Jobs
```

## [Syslog-ng](https://github.com/MrM8BRH/Splunk/blob/main/Splunk%20Deployment/Syslog-ng.md)

### Enable More Auditing Policies on Windows
*   Run - Group Policy > Computer Configuration > Windows Settings > Security Settings > Advanced Audit Policy Configuration

## Upgrade Splunk Enterprise (Linux)
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

## Uninstall Splunk Enterprise (Linux)
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
 
## Disable Splunk Web
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

## Uninstall an app or add-on
- Delete the app and its directory. The app and its directory are typically located in `$SPLUNK_HOME/etc/apps/<appname>`.
- You may need to remove user-specific directories created for your app or add-on by deleting any files found here: `$SPLUNK_HOME/etc/users/*/<appname>`.

## JAVA for DB Connect app
```
# PATH: /opt/splunk/etc/apps/splunk_app_db_connect/linux_x86
# URL: https://www.oracle.com/java/technologies/javase/jdk11-archive-downloads.html
# Permission: chown -R splunk:splunk /opt/splunk
```

## Splunk Admin Password Reset
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
#### Log In with New Password
After the restart, a new `passwd` file will be generated, and you should be able to log in successfully with your new password. 


Troubleshoot & Others
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
/opt/splunk/bin/splunk migrate migrate-kvstore

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
```
