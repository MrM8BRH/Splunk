# FortiGate Application for Splunk Installation & Configuration

## [Syslog-ng](https://github.com/MrM8BRH/Splunk/blob/main/Splunk%20Deployment/Syslog-ng.md)
 
## Splunk Universal Forwarder Configuration
 
Add the following to `inputs.conf`
```
[monitor:///var/log/syslog-ng/default/<FortiGate-IP>/*.log]
sourcetype = fortigate_log
disabled = false
```
```
nano /opt/splunkforwarder/etc/system/local/inputs.conf
```

[#] Restart the Universal Forwarder
```
/opt/splunkforwarder/bin/splunk restart
```
 
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

---

## Troubleshooting

 On the search head server, Edit ```$SPLUNK_HOME/etc/apps/Splunk_TA_fortinet_fortigate/default/props.conf```
 ```
 [fortinet]
 TRANSFORMS-force_sourcetype_fgt = force_sourcetype_fgt_traffic,force_sourcetype_fgt_utm,force_sourcetype_fgt_event
 SHOULD_LINEMERGE = false
 ```
 
 ```
 /opt/splunk/bin/splunk restart
 ```

## Resources:
 - [Splunk - Fortinet](https://lantern.splunk.com/Data_Descriptors/Fortinet) 
 - [Fortinet-Splunk-Deployment-Guide](https://www.fortinet.com/content/dam/fortinet/assets/alliances/Fortinet-Splunk-Deployment-Guide.pdf)

