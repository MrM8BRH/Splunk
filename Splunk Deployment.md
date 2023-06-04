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
*   `sestatus`
*   `nano /etc/selinux/config`
*   `SELINUX=disabled`

## Disable Firewall:
```
systemctl stop firewalld
systemctl disable firewalld
systemctl status firewalld
```

## Disable Transparent Huge Pages (THP):

Author: [Barakat Abweh](https://github.com/barakat-abweh/disable-transparent-Huge-Pages) 

*   `vi /etc/systemd/system/disable-thp.service`
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

```diff
- After completing the above, restart the system
reboot
```

## Splunk (Linux)
*   `rpm -ivh <Package>`
*   `/opt/splunk/bin/splunk start --accept-license`
*   `/opt/splunk/bin/splunk enable boot-start`

## Enable SSL:
*   `vi /opt/splunk/etc/system/local/web.conf`
```text-plain
[settings]
max_upload_size = 1024
enableSplunkWebSSL = true
```
*   `chown -R splunk:splunk /opt/splunk`
*   `chmod 755 /opt/splunk/etc/system/local/web.conf`
*   `/opt/splunk/bin/splunk restart`

## Indexer Server
*   `Forwarding and reciving > Add new`
*   `Add indexes : wineventlog, linux, fgt_log .. etc`
*   `Install Addons`

## Deployment Server
*   `Install Windows/Linux Addons`
*   `mkdir /opt/splunk/etc/deployment-apps/output ; cd output ; mkdir local ; cd local`
*   `touch outputs.conf ; nano outputs.conf`
```
[tcpout] defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = 192.168.1.50:9997

[tcpout-server://192.168.1.50:9997]
```
*   `cp -r /opt/splunk/etc/apps/Splunk\_TA\_windows /opt/splunk/etc/deployment-apps`
*   `cd /opt/splunk/etc/deployment_apps/Splunk\_TA\_windows/ ; mkdir local`
*   `cp default/inputs.conf local/ ; nano local/inputs.conf`
*   `chown -R splunk:splunk /opt/splunk`
*   `/opt/splunk/bin/splunk restart`

## SearchHead Server
 ```
outputs.conf (Deployment Server) -> /opt/splunk/etc/system/local (Search Head + Deployment)
- Install Apps & Addons
- Monitoring Console -> Settings -> General Setup [Standalone -> Distributed]
- Monitoring Console -> General Setup -> Distuibuted ( Add [Indexer:8089 + Deployment:8089] ) +
Edit Roles
Indexer -> Indexer
Deployment -> Deployment
Search Head -> Search Head + KV Store + License Master
```

## Splunk Forwarder (Linux)
*   `Download`
*   `sudo tar -xzvf splunkforwarder.tgz -C /opt`
*   `cd /opt/SplunkForwarder`
*   `./splunk start --accept-license`
*   `./splunk enable boot-start -user splunk`
*   `./splunk add forward-server <indexer-ip>:9997`
*   `./splunk set deploy-poll <deployment-ip>:8089`
*   `./splunk add monitor -auth admin:password /var/log/..etc`
*   `Verify: go to data summary`


## Syslog-ng
[Install Syslog-ng]

* On RHEL 7: Enable the so-called “optional” repository , which contains a number of packages that are required to start syslog-ng:

 `subscription-manager repos --enable rhel-7-server-optional-rpms`
* On RHEL 8: Enable the so-called "suplementary" repository

 `subscription-manager repos --enable rhel-8-for-x86_64-supplementary-rpms`
* On RHEL 9 and compatibles check: https://docs.fedoraproject.org/en-US/epel/#_el9

[#] CentOS 7
```
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh epel-release-latest-7.noarch.rpm
```

[#] CentOS 8
```
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
rpm -Uvh epel-release-latest-8.noarch.rpm
```

`cd /etc/yum.repos.d/`

[#] CentOS 7
`wget https://copr.fedorainfracloud.org/coprs/czanik/syslog-ng336/repo/epel-7/czanik-syslog-ng41-epel-7.repo`

[#] CentOS 8
`wget https://copr.fedorainfracloud.org/coprs/czanik/syslog-ng336/repo/epel-8/czanik-syslog-ng41-epel-8.repo`

```
dnf install syslog-ng
systemctl enable syslog-ng
systemctl start syslog-ng
cp /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.backup
```
`nano /etc/syslog-ng/syslog-ng.conf`
<details>
 
 <summary>Conf File</summary>
 
```
@version:3.5
@include "scl.conf"
# syslog-ng configuration file.
#
# This should behave pretty much like the original syslog on RedHat. But
# it could be configured a lot smarter.
#
# See syslog-ng(8) and syslog-ng.conf(5) for more information.
#
# Note: it also sources additional configuration files (*.conf)
#       located in /etc/syslog-ng/conf.d/
options {
flush_lines (0);
time_reopen (10);
create_dirs(yes);
log_fifo_size (2048);
log_msg_size(8192);
chain_hostnames (no);
use_dns (no);
use_fqdn (no);
keep_hostname (yes);
perm(0644);
dir_perm(0755);
time_reopen (10);
};
source s_syn {
#    system();
#   internal();
udp(ip(0.0.0.0) port(5514));
};
source s_syf {
#    system();
#   internal();
udp(ip(0.0.0.0) port(6514));
};
source s_syd {
#    system();
#   internal();
udp(ip(0.0.0.0) port(514));
};
destination d_n { file("/var/log/syslog-ng/networks/$HOST/$YEAR$MONTH$DAY.log"); };
destination d_f { file("/var/log/syslog-ng/security/$HOST/$YEAR$MONTH$DAY.log"); };
destination d_d { file("/var/log/syslog-ng/default/$HOST/$YEAR$MONTH$DAY.log"); };
log { source(s_syn); destination(d_n); };
log { source(s_syf); destination(d_f); };
log { source(s_syd); destination(d_d); };
# Source additional configuration files (.conf extension only)
@include "/etc/syslog-ng/conf.d/*.conf"
# vim:ft=syslog-ng:ai:si:ts=4:sw=4:et:
```
</details>

## Log Retention:
[For Indexer Server]
```
# Append frozenTimePeriodInSecs in indexes.conf
# /opt/splunk/etc/apps
# /opt/splunk/etc/system
# find / -name "indexes.conf"
frozenTimePeriodInSecs = 31556926
```

[For Syslog Server]
```
crontab –e
0 5 * * * find /var/log/syslog-ng/networks/ -type f -name \*.log -mtime +7 -exec rm {} \;
0 5 * * * find /var/log/syslog-ng/security/ -type f -name \*.log -mtime +7 -exec rm {} \;
0 5 * * * find /var/log/syslog-ng/default/ -type f -name \*.log -mtime +7 -exec rm {} \;
```

## Enable More Auditing Policies on Windows
*   Run - Group Policy > Computer Configuration > Windows Settings > Security Settings > Advanced Audit Policy Configuration

## Active Directory Dashboard
Author: [Yousef Hawwari](https://github.com/yousefhawwari)

<details>
 
 <summary>Source Code</summary>
 
```
<form theme="dark">
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
          <query>index=wineventlog host="ps-dc01"  source="*:Security" signature="A user account was locked out"  |eval time = strftime(_time,"%c") |stats count(name) |rename time as "Time" , user as "User Name" , name as "Action" , src_user as "Locked/Unlocked By", host as "Hostname"</query>
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
          <query>host="ps-dc0*" index="wineventlog" signature="An attempt was made to change an account's password" OR signature="An attempt was made to reset an accounts password" |eval time = strftime(_time,"%c") |stats count(name)</query>
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
          <query>host="ps-dc0*" index="wineventlog" signature="A user account was changed" |eval time = strftime(_time,"%c") |stats count(name)</query>
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
          <query>index=wineventlog host="ps-dc01" source="*:Security" EventCode=4735 OR EventCode=4737 |eval time = strftime(_time,"%c") |top limit=10 TargetUserName</query>
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
          <query>index=wineventlog host="ps-dc01" source="*:Security" OR name="User name is correct but the password is wrong" | eval time = strftime(_time,"%c") |top limit=10 user</query>
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
          <query>index=wineventlog host="ps-dc01" source="*:Security" signature="A user account was locked out" |eval time = strftime(_time,"%c") |top limit=10 user</query>
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
          <query>index=wineventlog host="ps-dc01" source="*:Security" signature="A user account was unlocked" |eval time = strftime(_time,"%c") |top limit=10 src_user</query>
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
          <query>index="wineventlog" host="ps-dc0*" EventCode!=4624 AND EventCode!=4634 |search user=$user_name$|eval time = strftime(_time,"%c") | transaction name maxspan=30s |table time,name,user,src,dest |rename time as "Time" , name as "Action" , user as "Admin User" , dest as "Destination DC", src as "Device"</query>
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
          <query>index=wineventlog host="ps-dc01"  source="*:Security" name="User name does not exist" OR name="User name is correct but the password is wrong" | eval time = strftime(_time,"%c") | transaction name, user maxspan=1m |table time,host,name,src_ip,user |rename time as "Time" , name as "Action" , src_ip as "Destination IP Address" , user as "User Name", host as "Hostname"</query>
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
          <query>index=wineventlog host="ps-dc01"  source="*:Security" signature="A user account was locked out" OR signature="A user account was unlocked" |eval time = strftime(_time,"%c") |table time,host,user,name,src_user |rename time as "Time" , user as "User Name" , name as "Action" , src_user as "Locked/Unlocked By", host as "Hostname"</query>
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
          <query>index=wineventlog host="ps-dc01"  source="*:Security" EventCode=4722 OR EventCode=4725 |eval time = strftime(_time,"%c") |table time,host,name,user,src_user |rename time as "Time" , name as "Action" , user as "Target User" , src_user as "Account Enabled/Disabled By", host as "Hostname"</query>
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
          <query>index=wineventlog host="ps-dc01" source="*:Security" signature="A user account was changed" |eval time = strftime(_time,"%c") |table time,host,name,user,src_user,dest |rename time as "Time" , name as "Action" , user as " Target User" , src_user as "Changed By" , dest as "Destination DC", host as "Hostname"</query>
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
          <query>index=wineventlog host="ps-dc01"  source="*:Security" EventCode=4761 OR EventCode=4762 OR EventCode=4728 OR EventCode=4729 |eval time = strftime(_time,"%c") |table time,host,name,MemberName,Group_Name,src_user |rename time as "Time" , name as "Action" , MemberName as "Member Name Added/Removed" , Group_Name as "Group Name" , src_user as "Member Added/Removed By :", host as "Hostname"</query>
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
          <query>index=wineventlog host="ps-dc01"  source="*:Security" EventCode=4735 OR EventCode=4737 |eval time = strftime(_time,"%c") |table time,host,name,src_user,TargetUserName,dest,session_id |rename time as "Time" , name as "Action" , src_user as "Source User", TargetUserName as " Target Group " , dest as " Destination DC" , session_id as "Session ID", host as "Hostname"</query>
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
          <query>index=wineventlog host="ps-dc01"  source="*:Security" EventCode=4720 |eval time = strftime(_time,"%c") |table time,host,name,user,Logon_ID,src_user,dest |rename time as "Time" , name as "Action" , user as "Created User" , Logon_ID as "Session ID" ,src_user as "User Created By :", dest as "Destination DC", host as "Hostname"</query>
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
          <query>index=wineventlog host="ps-dc01"  source="*:Security" EventCode=4726 |eval time = strftime(_time,"%c") |table time,host,name,user,src_user,dest |rename time as "Time" , name as "Action" , src_user as "Deleted By : " , dest as "Destination DC", host as "Hostname", user as "User"</query>
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
          <query>index=wineventlog host="ps-dc01"  source="*:Security" signature="An attempt was made to change an account's password" OR signature="An attempt was made to reset an accounts password" |eval time = strftime(_time,"%c") |table time,host,name,user,src_user |rename time as "Time" , name as "Action" , user as "Target User" , src_user as "Password Changed/Reset By", host as "Hostname"</query>
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


## Split a .pfx File into .pem and .key Files Using OpenSSL
The following command will generate a private key file without a password from your .pfx file (requires password):

`openssl pkcs12 -in certificate.pfx -out privateKey.key -nocerts -nodes`

The following command will generate a .pem certificate file from your .pfx file which will include any intermediate and root certificates that may be included in the .pfx file. (requires password):

`openssl pkcs12 -in certificate.pfx -out certificate.pem -nokeys -clcerts`

`/opt/splunk/etc/auth`

## Upgrade Splunk Enterprise
```
rpm -Uvh <Package>
/opt/splunk/bin/splunk status
<q> <y> <y>
/opt/splunk/bin/splunk restart
```
##  Here's an example of how you can monitor a stanza in Splunk on both Windows and Linux.
For Windows:
```
[monitor://C:\path\to\logs]
disabled = false
index = myindex
host_segment = 5
```
 For Linux:
 ```
[monitor:///path/to/logs]
disabled = false
index = myindex
host_segment = 5
```
```diff
- Restart the service after modifying the monitor stanza.
```
For Windows:
```
Restart-Service -Name "SplunkForwarder" 
```
For Linux:
```
/opt/splunkforwarder/bin/splunk restart
```
## Blacklist EventCode
```
[WinEventLog://Security]
disabled = 0
blacklist1 = EventCode="4662" Message="Object Type:s+(?!groupPolicyContainer)"
blacklist2 = EventCode="4625"
blacklist3 = EventCode="4625" ComputerName="specific-comp-name" Message="Account\sName: \s+specific-user-name"
blacklist4 = EventCode="4625" ComputerName="specific-comp-name" Message="specific-user-name"
```
 
## A storage location for logs
```
/opt/splunk/var
```
