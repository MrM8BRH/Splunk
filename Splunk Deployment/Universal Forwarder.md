## Install & Configure Splunk Universal Forwarder on Linux
```
# Create the Splunk user and group
useradd -m splunkfwd
groupadd splunkfwd

# Install Splunk Universal Forwarder using RPM:
rpm -ivh splunkforwarder_package_name.rpm

# Install Splunk Universal Forwarder using Dpkg:
dpkg -i splunkforwarder_package_name.deb

# Install Splunk Universal Forwarder using Tar:
tar xvzf splunkforwarder_package_name.tgz -C /opt

# Check Splunk status and accept the license 
/opt/splunkforwarder/bin/splunk status --accept-license # (1)
/opt/splunkforwarder/bin/splunk status --accept-license --answer-yes --no-prompt --seed-passwd `head -c 500 /dev/urandom | sha256sum | base64 | head -c 16 ; echo` # (2)

#  Set the deployment server (Splunk deployment client):
/opt/splunkforwarder/bin/splunk set deploy-poll <deployment-ip>:8089

# Enable the Splunk Universal Forwarder to start on boot:
/opt/splunkforwarder/bin/splunk enable boot-start -systemd-managed 1 -user splunkfwd -group splunkfwd

# Start Splunk Universal Forwarder
/opt/splunkforwarder/bin/splunk start

# Add a forward server (indexer) to send data:
/opt/splunkforwarder/bin/splunk add forward-server <indexer-ip>:9997

# Remove a forward server (indexer):
/opt/splunkforwarder/bin/splunk remove forward-server <indexer-ip>:9997

# Edit the deploymentclient.conf file:
nano /opt/splunkforwarder/etc/system/local/deploymentclient.conf

# Extract tgz file
gunzip <archive.tgz>

# Extract tar file
tar -xvf <archive.tar>
```
## Resources
- [Leveraging Windows Event Log Filtering and Design Techniques in Splunk](https://hurricanelabs.com/splunk-tutorials/leveraging-windows-event-log-filtering-and-design-techniques-in-splunk/)
- [Splunk Add-on for Microsoft Windows](https://splunk.github.io/splunk-add-on-for-microsoft-windows/)
- [Splunk Add-on for Unix and Linux](https://splunk.github.io/splunk-add-on-for-unix-and-linux/)

***Universal Forwarder 10.2***
- [Monitor files and directories with inputs.conf](https://help.splunk.com/en/splunk-enterprise/get-started/get-data-in/10.2/get-data-from-files-and-directories/monitor-files-and-directories-with-inputs.conf)
- [Install a *nix universal forwarder](https://help.splunk.com/en/splunk-enterprise/forward-and-process-data/universal-forwarder-manual/10.2/install-the-universal-forwarder/install-a-nix-universal-forwarder)
- [Install a Windows universal forwarder](https://help.splunk.com/en/splunk-enterprise/forward-and-process-data/universal-forwarder-manual/10.2/install-the-universal-forwarder/install-a-windows-universal-forwarder)
- [Upgrade the universal forwarder](https://help.splunk.com/en/splunk-enterprise/forward-and-process-data/universal-forwarder-manual/10.2/upgrade-or-uninstall-the-universal-forwarder/upgrade-the-universal-forwarder)
- [Uninstall the universal forwarder](https://help.splunk.com/en/splunk-enterprise/forward-and-process-data/universal-forwarder-manual/10.2/upgrade-or-uninstall-the-universal-forwarder/uninstall-the-universal-forwarder)
- [Route and filter data](https://help.splunk.com/en/splunk-enterprise/forward-and-process-data/forwarding-and-receiving-data/10.2/perform-advanced-configuration/route-and-filter-data#Route_and_filter_data)
- [Create advanced filters with the 'whitelist' and 'blacklist' settings](https://help.splunk.com/en/splunk-enterprise/get-started/get-data-in/10.2/get-windows-data/monitor-windows-event-log-data-with-splunk-enterprise#create-advanced-filters-with-the-whitelist-and-blacklist-settings-0)
- [Set up client filters](https://help.splunk.com/en/splunk-enterprise/administer/update-your-deployment/10.2/configure-the-agent-management-system/set-up-agent-filters)

## 25 Linux Logs to Collect and Monitor
- `/var/log/auth.log`: documentation for failed and successful logins and authentication on Debian/Ubuntu
- `/var/log/secure`: documentation for failed and successful logins and authentication on RedHat/CentOS
- `/var/log/boot.log`: information about startup, shutdown, and boot, including initialization script
- `/var/log/maillog`: activities related to mail servers
- `/var/log/kern`: kernel logs and warning data for troubleshooting custom kernels
- `/var/log/syslog`: consolidated system-wide activity across different components
- `/var/log/messages`: general system information, like boot errors, application service errors, or hardware issues
- `/var/log/daemon.log`: information about background daemons running on the system
- `/var.log/cups`: printer and printing information
- `var/log/mysqld.log`: debugging, failure, and success of MySQL daemon
- `/var/log/cron`: record of all Crond-related messages (cron jobs) like when jobs are initiated or terminated
- `/var/log/faillog`: failed login attempts against the system, useful for security incident and credential attack investigations
- `/var/log/btmp`: failed login attempts by individual user, useful for security incident and credential attack investigations (more detailed log with IP, User
- `/var/log/auth.log`: system authorization information, like user login and authentication method
- `/var/log/utmp`: user current login state
- `/var/log/wtmp`: user login and logout records
- `/var/log/httpd/`: error and access log files for Apache httpd daemon, like memory issues or requests from HTTP
- `/var/log/pureftp.log`: FTP connections using pureftp process, like login successes and failures
- `var/log/yum.log`: record on package installations using Red Hat Enterprise yum command
- `/var/log/dpkg.log`: record on package installation or removal using the dpkg command
- `/var/log/lastlog`: every user’s most recent login
- `/var/log/xferlog`: FTP file transfer session information, like file names and user-initiated transfers
- `​​/var/log/Xorg.x.log`: XWindows system messages
- `/var/log/audit/audit.log`: records user activity related to the Linux Audit daemon (auditd)
- `/var/log/samba/`: record of activity by the samba daemon that connects Windows/Linux filesystems

## Blacklist/Whitelist EventCode
```
[WinEventLog://Security]
disabled = 0
blacklist1 = EventCode="4662" Message="Object Type:s+(?!groupPolicyContainer)"
blacklist2 = EventCode="4625"
blacklist3 = EventCode="4625" ComputerName="specific-comp-name" Message="Account\sName: \s+specific-user-name"
blacklist4 = EventCode="4625" ComputerName="specific-comp-name" Message="specific-user-name"
blacklist5 = EventCode="5145" Message="Access Mask:\s*0x100081" #File Server
blacklist6 = EventCode="5145" Message="(?s).*Account Name:\s+(user).*Access Mask:\s+0x80.*" #File Server
whitelist = 4722,4725,4740,4767,4738,4720,4723,4724,4726,4735,4737,4761,4762,4728,4729,4776,4780,4688,4648
```

## Discard specific events and keep the rest
1. This example discards all `sshd` events in `/var/log/messages` by sending them to `nullQueue`:
Under props.conf
```
[source::/var/log/messages]
TRANSFORMS-null= setnull
```
2. Create a corresponding stanza in `transforms.conf`. Set `DEST_KEY` to "queue" and `FORMAT` to "nullQueue":
```
[setnull]
REGEX = \[sshd\]
DEST_KEY = queue
FORMAT = nullQueue
```
3. Restart Splunk Enterprise.

REGEX
Website for testing: `https://regex101.com/`

Examples:
```
\bgroup="N\/A"
\bsshd\b
\bn\/?a(?:[aeiouAEIOU]*|)\b|\bN\/?A(?:[aeiouAEIOU]*|)\b
```
