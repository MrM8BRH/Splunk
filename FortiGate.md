- [FortiGate Add-on for Splunk](https://splunkbase.splunk.com/app/2846)
- * You can install FortiGate Add-on for Splunk on search head, indexer, forwarder or single instance Splunk server.

Edit $SPLUNK_HOME/etc/apps/Splunk_TA_fortinet_fortigate/default/props.conf
```
[fortinet]
TRANSFORMS-force_sourcetype_fgt = force_sourcetype_fgt_traffic,force_sourcetype_fgt_utm,force_sourcetype_fgt_event
SHOULD_LINEMERGE = false
```

Restart Splunk

--> Check:
  Search & Reporting App, index=fortigate, Check for sourcetype feild (fortigate_traffic, fortigate_utm, fortigate_event)


- [FortiGate Application for Splunk](https://splunkbase.splunk.com/app/2800)

Settings, Data models, Fortinet FOS Log, accelrate
