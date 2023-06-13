# FortiGate Application for Splunk Installation & Configuration

## Install Syslog-ng
### Syslog-ng for debian

```apt install syslog-ng```

If you face dependencies issues:
 ```
 wget -qO - https://ose-repo.syslog-ng.com/apt/syslog-ng-ose-pub.asc | sudo apt-key add -
 ```
 ```
 echo "deb https://ose-repo.syslog-ng.com/apt/ nightly ubuntu-jammy" | sudo tee -a /etc/apt/sources.list.d/syslog-ng-ose.list
 ```
 ```
 apt update
 ```
 ```
 apt install syslog-ng
 ```

- [FortiGate Add-on for Splunk](https://splunkbase.splunk.com/app/2846)
  * You can install FortiGate Add-on for Splunk on search head, indexer, forwarder or single instance Splunk server.
 <br>

 Edit $SPLUNK_HOME/etc/apps/Splunk_TA_fortinet_fortigate/default/props.conf
 ```
 [fortinet]
 TRANSFORMS-force_sourcetype_fgt = force_sourcetype_fgt_traffic,force_sourcetype_fgt_utm,force_sourcetype_fgt_event
 SHOULD_LINEMERGE = false
 ```

 Restart Splunk

 --> Check:
   - Search & Reporting App, index=fortigate, Check for sourcetype feild (fortigate_traffic, fortigate_utm, fortigate_event)
   - Enterprise Security -> Security Domains
<br>
<br>

[FortiGate Application for Splunk](https://splunkbase.splunk.com/app/2800)

  * Download and install the App
  * Settings, Data models, Fortinet FOS Log, accelrate
---
<br>

Resources:
 - [Splunk - Fortinet](https://lantern.splunk.com/Data_Descriptors/Fortinet) 
 - [Fortinet-Splunk-Deployment-Guide](https://www.fortinet.com/content/dam/fortinet/assets/alliances/Fortinet-Splunk-Deployment-Guide.pdf)

