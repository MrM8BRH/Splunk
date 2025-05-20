## Install FortiGate Add-on for Splunk

[FortiGate Add-on for Splunk](https://splunkbase.splunk.com/app/2846)
  * You can install FortiGate Add-on for Splunk on search head, indexer, forwarder or single instance Splunk server.
 
## Install FortiGate Application for Splunk

[FortiGate Application for Splunk](https://splunkbase.splunk.com/app/2800)

  * Download and install the App
  * Settings, Data models, Fortinet FOS Log, accelrate
  * ```/opt/splunk/bin/splunk restart```
  * Search & Reporting App, index=fortigate, Check for sourcetype feild (fortigate_traffic, fortigate_utm, fortigate_event)
  * Enterprise Security -> Security Domains

 
[Fortinet-Splunk-Deployment-Guide](https://www.fortinet.com/content/dam/fortinet/assets/alliances/Fortinet-Splunk-Deployment-Guide.pdf)
[Technical Tip: How to configure syslog on FortiGate ](https://community.fortinet.com/t5/FortiGate/Technical-Tip-Change-Source-IP-for-SYSLOG/ta-p/230218)

FortiGate Firewall Side
```
config log syslogd2 setting
    set status enable
    set server "Syslog IP"
    set source-ip "Forti Mgmt IP"
end
```
