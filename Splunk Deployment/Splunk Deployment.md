## CentOS
### Downloading
https://docs.centos.org/en-US/centos/install-guide/downloading/
### Quick Installation Guide
https://docs.centos.org/en-US/centos/install-guide/Simple_Installation/


## Tools and Dependencies
```
yum update -y
yum install -y dnf
dnf install -y net-tools nano bind-utils chkconfig
```

## Disable SELinux
```
# Check the current status and mode of SELinux.
sestatus

# Opens the SELinux configuration file using the nano text editor.
nano /etc/selinux/config

# A configuration option that can be set in the SELinux configuration file to disable SELinux on the system,
# preventing it from enforcing security policies.
SELINUX=disabled
```

## Disable Firewall
```
# Stops the "firewalld" service immediately.
systemctl stop firewalld

# Disables the "firewalld" service from starting automatically on system boot.
systemctl disable firewalld

# Checks the current status of the "firewalld" service.
systemctl status firewalld
```

## Disable Transparent Huge Pages (THP)

Author: [Barakat Abweh](https://github.com/barakat-abweh/disable-transparent-Huge-Pages) 

*   `nano /etc/systemd/system/disable-thp.service`
```text-plain
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

## Extend-ulimit-open-files

Author: [Barakat Abweh](https://github.com/barakat-abweh/extend-ulimit-open-files)
*   `nano Extend-ulimit-open-files.sh`
```text-plain
# !/bin/bash
echo "fs.file-max=65535" >/etc/sysctl.conf
cp /etc/systemd/user.conf /etc/systemd/user.conf.bckup
cp /etc/systemd/system.conf /etc/systemd/system.conf.bckup
sed -i 's/^#DefaultLimitNOFILE=/DefaultLimitNOFILE=65535/' /etc/systemd/user.conf
sed -i 's/^#DefaultLimitNOFILE=/DefaultLimitNOFILE=65535/' /etc/systemd/system.conf
echo "splunk               soft    nproc           65535" >> /etc/security/limits.conf
echo "splunk               hard    nproc           65535" >> /etc/security/limits.conf
echo "splunk               soft    nofile          65535" >> /etc/security/limits.conf
echo "splunk               hard    nofile          65535" >> /etc/security/limits.conf
```
*   `chmod +x Extend-ulimit-open-files.sh`
*   `./Extend-ulimit-open-files.sh`
```diff
- After completing the above, restart the system
reboot
```

## Splunk Enterprise (Linux)
```
# Install Splunk using RPM:
rpm -ivh <Package>

# Start Splunk and accept the license:
/opt/splunk/bin/splunk start --accept-license

# Enable Splunk to start on boot:
/opt/splunk/bin/splunk enable boot-start
```

## Enable SSL:
*   `vi /opt/splunk/etc/system/local/web.conf`
```text-plain
[settings]
max_upload_size = 1024
enableSplunkWebSSL = true
```
*   `/opt/splunk/bin/splunk restart`

## Forwarding Splunk's internal logs to the indexers
*    `nano /opt/splunk/etc/system/local/outputs.conf`
```
[tcpout] defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = 192.168.1.50:9997

[tcpout-server://192.168.1.50:9997]
```

## Indexer Server
*   `Settings -> Forwarding and reciving -> Configure receiving`
*   `Settings -> Indexes - Add indexes like: wineventlog, linux, fortigate, crowdstrike, pam, f5, oracle, mysql .. etc`
*   `Install Addons`

Log Retention:

- `find /opt/splunk/ -name "indexes.conf"`
```
[your_index_name]
frozenTimePeriodInSecs = 31556926
```

## Deployment Server
*   `Install Windows/Linux Addons`
*   `mkdir -p /opt/splunk/etc/deployment-apps/output/local`
*   `cd /opt/splunk/etc/deployment-apps/output/local`
*   `nano outputs.conf`
```
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
```
chown -R splunk:splunk /opt/splunk
/opt/splunk/bin/splunk restart
```
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
- output -> *
- windows
- linux
```

```
chown -R splunk:splunk /opt/splunk
/opt/splunk/bin/splunk restart
```
Reload the configuration for the Splunk Deployment Server
```
/opt/splunk/bin/splunk reload deploy-server
```

## SearchHead Server
 ```
- Install/Hide Apps & Addons (Apps -> Manage Apps)
- Apps -> Search & Reporting ->  Data Summary
- Settings -> Server settings -> General settings 
- Settings -> Server settings -> Email settings
- Settings -> Monitoring Console -> Settings -> Alerts Setup
- Settings -> Monitoring Console -> Settings -> Forwarder Monitoring Setup
- Settings -> Monitoring Console -> Forwarders -> forwarder_instance
- Settings -> Distributed search -> Search peers - New Search peers ( Add [Indexer:8089 + Deployment:8089] )
- Settings -> Monitoring Console -> Settings -> General Setup [Standalone -> Distributed]
   Edit Roles
              Indexer -> Indexer
              Deployment -> Deployment
              Search Head -> Search Head + KV Store + License Master
- Turning off indexing on the Search Head ("outputs.conf" file in the "/opt/splunk/etc/system/local") : 
We will make indexAndForward flag = false
```
Enterprise Security App
```
Configure -> Content -> Content Management (Type: Correlation Search)
Configure -> General -> General Settings (Distributed Configuration Management)
Configure -> Data Enrichment -> Threat Intelligence Management
Configure -> Data Enrichment -> Asset and Identity Management -> (Asset Lookups + Identity Lookups) -> New -> LDAP Lookup
Configure -> Data Enrichment -> Asset and Identity Management -> Correlation Setup -> Enable for all sourcetypes
```

## [Syslog-ng](https://github.com/MrM8BRH/Splunk/blob/main/Syslog-ng.md)

## Enable More Auditing Policies on Windows
*   Run - Group Policy > Computer Configuration > Windows Settings > Security Settings > Advanced Audit Policy Configuration

## Active Directory Dashboard
Author: [Yousef Hawwari](https://github.com/yousefhawwari)

<details>
 
 <summary>Source Code</summary>
 
```
<form version="1.1" theme="dark">
  <label>Active Directory Dashboard</label>
  <fieldset submitButton="false" autoRun="false">
    <input type="time" token="field1">
      <label></label>
      <default>
        <earliest>-24h@h</earliest>
        <latest>now</latest>
      </default>
    </input>
  </fieldset>
  <row>
    <panel>
      <single>
        <title>Number of Locked Users - Last 24 H</title>
        <search>
          <query>index=wineventlog host="*"  source="*:Security" signature="A user account was locked out"  |eval time = strftime(_time,"%c") |stats count(name) |rename time as "Time" , user as "User Name" , name as "Action" , src_user as "Locked/Unlocked By", host as "Hostname"</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
        <option name="colorMode">block</option>
        <option name="drilldown">none</option>
        <option name="rangeColors">["0x53a051","0x0877a6","0xf8be34","0xf1813f","0xdc4e41"]</option>
        <option name="refresh.display">progressbar</option>
        <option name="useColors">1</option>
      </single>
    </panel>
    <panel>
      <single>
        <title>Number of Password Resets - Last 24 H</title>
        <search>
          <query>host="*" index="wineventlog" signature="An attempt was made to change an account's password" OR signature="An attempt was made to reset an accounts password" |eval time = strftime(_time,"%c") |stats count(name)</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
        <option name="colorMode">block</option>
        <option name="drilldown">none</option>
        <option name="rangeColors">["0x53a051","0x0877a6","0xf8be34","0xf1813f","0xdc4e41"]</option>
        <option name="useColors">1</option>
      </single>
    </panel>
    <panel>
      <single>
        <title>Number of User Account Changes - Last 24 H</title>
        <search>
          <query>host="*" index="wineventlog" signature="A user account was changed" |eval time = strftime(_time,"%c") |stats count(name)</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
        <option name="colorMode">block</option>
        <option name="drilldown">none</option>
        <option name="rangeColors">["0x53a051","0x0877a6","0xf8be34","0xf1813f","0xdc4e41"]</option>
        <option name="useColors">1</option>
      </single>
    </panel>
  </row>
  <row>
    <panel>
      <chart>
        <title>Top 10 Changed Security Groups</title>
        <search>
          <query>index=wineventlog host="*" source="*:Security" EventCode=4735 OR EventCode=4737 |eval time = strftime(_time,"%c") |top limit=10 TargetUserName</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="charting.chart">pie</option>
        <option name="charting.drilldown">all</option>
        <option name="refresh.display">progressbar</option>
      </chart>
    </panel>
    <panel>
      <chart>
        <title>Top 10 Users - Failed Logins</title>
        <search>
          <query>index=wineventlog host="*" source="*:Security" OR name="User name is correct but the password is wrong" | eval time = strftime(_time,"%c") |top limit=10 user</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="charting.chart">pie</option>
        <option name="charting.drilldown">all</option>
        <option name="refresh.display">progressbar</option>
      </chart>
    </panel>
  </row>
  <row>
    <panel>
      <chart>
        <title>Top 10 Locked out Users</title>
        <search>
          <query>index=wineventlog host="*" source="*:Security" signature="A user account was locked out" |eval time = strftime(_time,"%c") |top limit=10 user</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="charting.chart">bar</option>
        <option name="charting.drilldown">all</option>
        <option name="refresh.display">progressbar</option>
      </chart>
    </panel>
    <panel>
      <chart>
        <title>Top 10 Users To Unlock The Locked Accounts</title>
        <search>
          <query>index=wineventlog host="*" source="*:Security" signature="A user account was unlocked" |eval time = strftime(_time,"%c") |top limit=10 src_user</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="charting.chart">bar</option>
        <option name="charting.drilldown">none</option>
      </chart>
    </panel>
  </row>
  <row>
    <panel>
      <input type="text" token="user_name">
        <label>Username</label>
      </input>
      <table>
        <title>Active Directory Actions</title>
        <search>
          <query>index="wineventlog" host="*" EventCode!=4624 AND EventCode!=4634 |search user=$user_name$|eval time = strftime(_time,"%c") | transaction name maxspan=30s |table time,name,user,src,dest |rename time as "Time" , name as "Action" , user as "Admin User" , dest as "Destination DC", src as "Device"</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>Failed Login Details</title>
        <search>
          <query>index=wineventlog host="*"  source="*:Security" name="User name does not exist" OR name="User name is correct but the password is wrong" | eval time = strftime(_time,"%c") | transaction name, user maxspan=1m |table time,host,name,src_ip,user |rename time as "Time" , name as "Action" , src_ip as "Destination IP Address" , user as "User Name", host as "Hostname"</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="count">5</option>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>User Account Locked/Unlocked Actions</title>
        <search>
          <query>index=wineventlog host="*"  source="*:Security" signature="A user account was locked out" OR signature="A user account was unlocked" |eval time = strftime(_time,"%c") |table time,host,user,name,src_user |rename time as "Time" , user as "User Name" , name as "Action" , src_user as "Locked/Unlocked By", host as "Hostname"</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="count">5</option>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>User Account Enabled/Dsiabled</title>
        <search>
          <query>index=wineventlog host="*"  source="*:Security" EventCode=4722 OR EventCode=4725 |eval time = strftime(_time,"%c") |table time,host,name,user,src_user |rename time as "Time" , name as "Action" , user as "Target User" , src_user as "Account Enabled/Disabled By", host as "Hostname"</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="count">5</option>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
    <panel>
      <table>
        <title>User Account Changed Actions</title>
        <search>
          <query>index=wineventlog host="*" source="*:Security" signature="A user account was changed" |eval time = strftime(_time,"%c") |table time,host,name,user,src_user,dest |rename time as "Time" , name as "Action" , user as " Target User" , src_user as "Changed By" , dest as "Destination DC", host as "Hostname"</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="count">5</option>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>Group Member Added/Removed Actions</title>
        <search>
          <query>index=wineventlog host="*"  source="*:Security" EventCode=4761 OR EventCode=4762 OR EventCode=4728 OR EventCode=4729 |eval time = strftime(_time,"%c") |table time,host,name,MemberName,Group_Name,src_user |rename time as "Time" , name as "Action" , MemberName as "Member Name Added/Removed" , Group_Name as "Group Name" , src_user as "Member Added/Removed By :", host as "Hostname"</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="count">5</option>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
    <panel>
      <table>
        <title>Security Group Changed Actions</title>
        <search>
          <query>index=wineventlog host="*"  source="*:Security" EventCode=4735 OR EventCode=4737 |eval time = strftime(_time,"%c") |table time,host,name,src_user,TargetUserName,dest,session_id |rename time as "Time" , name as "Action" , src_user as "Source User", TargetUserName as " Target Group " , dest as " Destination DC" , session_id as "Session ID", host as "Hostname"</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="count">5</option>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>User Account Created Actions</title>
        <search>
          <query>index=wineventlog host="*"  source="*:Security" EventCode=4720 |eval time = strftime(_time,"%c") |table time,host,name,user,Logon_ID,src_user,dest |rename time as "Time" , name as "Action" , user as "Created User" , Logon_ID as "Session ID" ,src_user as "User Created By :", dest as "Destination DC", host as "Hostname"</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="count">5</option>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
    <panel>
      <table>
        <title>Deleted Users Actions</title>
        <search>
          <query>index=wineventlog host="*"  source="*:Security" EventCode=4726 |eval time = strftime(_time,"%c") |table time,host,name,user,src_user,dest |rename time as "Time" , name as "Action" , src_user as "Deleted By : " , dest as "Destination DC", host as "Hostname", user as "User"</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="count">5</option>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>Reset Password Actions</title>
        <search>
          <query>index=wineventlog host="*"  source="*:Security" signature="An attempt was made to change an account's password" OR signature="An attempt was made to reset an accounts password" |eval time = strftime(_time,"%c") |table time,host,name,user,src_user |rename time as "Time" , name as "Action" , user as "Target User" , src_user as "Password Changed/Reset By", host as "Hostname"</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="count">5</option>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
</form>
```
</details>

## Upgrade Splunk Enterprise (Linux)
```
# Upgrade Splunk using RPM:
rpm -Uvh <Package>

# Check the status of Splunk:
/opt/splunk/bin/splunk status

# Accept the license and perform a restart:
<q> <y> <y>
/opt/splunk/bin/splunk restart
```

## License
```
# Lists the current licenses installed and activated on your Splunk instance.
/opt/splunk/bin/splunk list license

# Remove a specific license from the Splunk instance, identified by the license hash.
/opt/splunk/bin/splunk remove license <hash>
```

## Uninstall Splunk Enterprise (Linux)
```
# Uninstall Splunk using RPM:
rpm -e `rpm -qa | grep -i splunk`

# Remove the Splunk installation directory:
sudo rm -r /opt/splunk
```
 
## A storage location for logs
```
cd /opt/splunk/var/lib/splunk
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

## JAVA for DB Connect app
```
# PATH: /opt/splunk/etc/apps/splunk_app_db_connect/linux_x86
# URL: https://www.oracle.com/java/technologies/javase/jdk11-archive-downloads.html
# Permission: chown -R splunk:splunk /opt/splunk
```
