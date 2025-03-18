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
/opt/splunkforwarder/bin/splunk enable boot-start                                                           # (1)
/opt/splunkforwarder/bin/splunk enable boot-start -systemd-managed 1 -user splunkfwd -group splunkfwd       # (2)

# Start Splunk Universal Forwarder
/opt/splunkforwarder/bin/splunk start

# Add a forward server (indexer) to send data:
/opt/splunkforwarder/bin/splunk add forward-server <indexer-ip>:9997

# Remove a forward server (indexer):
/opt/splunkforwarder/bin/splunk remove forward-server <indexer-ip>:9997

# Edit the deploymentclient.conf file:
nano /opt/splunkforwarder/etc/system/local/deploymentclient.conf

# Library variable
export $LD_LIBRARY_PATH=/usr/lib:/opt/splunkforwarder/lib

# Extract tgz file
gunzip <archive.tgz>

# Extract tar file
tar -xvf <archive.tar>

# AIX
## This command invokes the following system commands to register the forwarder in the System Resource Controller (SRC):
mkssys -G splunk -s splunkd -p <path to splunkd> -u <splunk user> -a _internal_exec_splunkd -S -n 2 -f 9

## When you enable automatic boot start, the SRC handles the run state of the forwarder. This means that you must use a different command to start and stop the forwarder manually:
- /usr/bin/startsrc -s splunkd to start the forwarder.
- /usr/bin/stopsrc -s splunkd to stop the forwarder.
```
## Uninstall Splunk Universal Forwarder on Linux
```
# Stop Splunk Universal Forwarder
/opt/splunkforwarder/bin/splunk stop

# RedHat Linux
rpm -e `rpm -qa | grep -i splunkforwarder`

# Debian Linux
dpkg -P splunkforwarder

# Remove the Splunk Universal Forwarder installation directory:
sudo rm -r /opt/splunkforwarder

# Delete the splunkfwd user and group, if they exist.
userdel splunkfwd
groupdel splunkfwd
```

##  Here's an example of how you can monitor a stanza in Splunk on both Windows and Linux.
For Windows:
```
[monitor://C:\path\to\logs]
disabled = false
index = myindex
sourcetype = source_type
# host = hostname
# host_segment = 5
```
 For Linux:
 ```
[monitor:///path/to/logs]
disabled = false
index = myindex
sourcetype = source_type
# host = hostname
# host_segment = 5
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
## Blacklist/Whitelist EventCode
```
[WinEventLog://Security]
disabled = 0
blacklist1 = EventCode="4662" Message="Object Type:s+(?!groupPolicyContainer)"
blacklist2 = EventCode="4625"
blacklist3 = EventCode="4625" ComputerName="specific-comp-name" Message="Account\sName: \s+specific-user-name"
blacklist4 = EventCode="4625" ComputerName="specific-comp-name" Message="specific-user-name"
blacklist5 = EventCode="5145" Access_Mask=0x100081
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
Resources
---------
- [Install a Windows universal forwarder](https://docs.splunk.com/Documentation/Forwarder/latest/Forwarder/InstallaWindowsuniversalforwarderfromaninstaller)
- [Install a *nix universal forwarder](https://docs.splunk.com/Documentation/Forwarder/latest/Forwarder/Installanixuniversalforwarder)
- [Configure the Splunk Add-on for Windows](https://docs.splunk.com/Documentation/AddOns/released/Windows/Configuration)
- [Route and filter data](https://docs.splunk.com/Documentation/Splunk/latest/Forwarding/Routeandfilterdatad#Route_and_filter_data)
- [Create advanced filters with the 'whitelist' and 'blacklist' settings](https://docs.splunk.com/Documentation/Splunk/latest/Data/MonitorWindowseventlogdata#Create_advanced_filters_with_the_.27whitelist.27_and_.27blacklist.27_settings)
- [Set up client filters](https://docs.splunk.com/Documentation/Splunk/latest/Updating/Filterclients)
