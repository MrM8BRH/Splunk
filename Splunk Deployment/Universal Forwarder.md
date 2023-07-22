[Install a Windows universal forwarder](https://docs.splunk.com/Documentation/Forwarder/latest/Forwarder/InstallaWindowsuniversalforwarderfromaninstaller)

[Configure the Splunk Add-on for Windows](https://docs.splunk.com/Documentation/AddOns/released/Windows/Configuration)

## Install & Configure UF on Linux
```
# Start Splunk Forwarder and accept the license:
/opt/splunkforwarder/bin/splunk start --accept-license

# Enable the Splunk Forwarder to start on boot:
/opt/splunkforwarder/bin/splunk enable boot-start -user splunk

# Add a forward server (indexer) to send data:
/opt/splunkforwarder/bin/splunk add forward-server <indexer-ip>:9997

# Remove a forward server (indexer):
/opt/splunkforwarder/bin/splunk remove forward-server <indexer-ip>:9997

#  Set the deployment server (Splunk deployment client):
/opt/splunkforwarder/bin/splunk set deploy-poll <deployment-ip>:8089

# Edit the deploymentclient.conf file:
nano /opt/splunkforwarder/etc/system/local/deploymentclient.conf

# Add a monitored file or directory to forward data:
/opt/splunkforwarder/bin/splunk add monitor -auth admin:password /var/log/..etc
```
## Uninstall UF on Linux
```
rpm -e `rpm -qa | grep -i splunk`
sudo rm -r /opt/splunkforwarder/
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
