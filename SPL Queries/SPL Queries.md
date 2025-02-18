## Windows Security Log Events
- [Windows Security Log Events](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/default.aspx)
- [Windows security encyclopedia](https://www.windows-security.org/windows-event-ids)
- [Windows Event Log Analysis](https://cybersecuritynews.com/windows-event-log-analysis/)
- [Security Log Defined](https://system32.eventsentry.com/)

## Resources
- [Security Content](https://research.splunk.com/detections/)
- [Splunk Use Cases](https://0xcybery.github.io/blog/Splunk+Use+Cases)
- [GoSplunk](https://gosplunk.com/)
- [Splunk ES Queries](https://github.com/shauntdergrigorian/splunkqueries)

---

Convert epoch time to a human readable time
```
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
```

<details>
<summary><b>Lists</b></summary>

List Saved Searches
```
| rest /servicesNS/-/-/saved/searches splunk_server=local 
| table title search
```

List All App Alerts
```
| rest/servicesNS/-/-/saved/searches 
| search alert.track=1 
| fields title description search disabled triggered_alert_count actions action.script.filename alert.severity cron_schedule
```

List Search App Alerts
```
| rest/servicesNS/-/search/saved/searches
| search alert.track=1
| fields title description search disabled triggered_alert_count actions action.script.filename alert.severity cron_schedule
```
List All Indexes
```
| rest /services/data/indexes 
| table title
```

List Splunk Clients
```
| rest /services/deployment/server/clients | table hostname,ip,dns,utsname,splunkVersion,build
```

List of sourcetypes in index(es)
```
| tstats count as totalCount min(_time) as start_date, max(_time) as end_date, max(_indextime) as recent_date dc(host) as hosts where index=* sourcetype=* by index, sourcetype
| convert timeformat="%Y/%m/%d %H:%M:%S" ctime(start_date)
| convert timeformat="%Y/%m/%d %H:%M:%S" ctime(end_date)
| convert timeformat="%Y/%m/%d %H:%M:%S" ctime(recent_date)
| table index sourcetype start_date end_date recent_date hosts totalCount
```
</details>

<details>
<summary><b>Orphaned scheduled searches</b></summary>
 
```
| rest timeout=600 splunk_server=local /servicesNS/-/-/saved/searches add_orphan_field=yes count=0 
| search orphan=1 disabled=0 is_scheduled=1 
| eval status = if(disabled = 0, "enabled", "disabled") 
| fields title eai:acl.owner eai:acl.app eai:acl.sharing orphan status is_scheduled cron_schedule next_scheduled_time next_scheduled_time actions 
| rename title AS "search name" eai:acl.owner AS owner eai:acl.app AS app eai:acl.sharing AS sharing
```
</details>

<details>
<summary><b>Truncation Issues</b></summary>
 
~ 1
```
index="_internal" sourcetype=splunkd source="*splunkd.log" log_level="WARN" "Truncating" 
| rex "line length >= (?<line_length>\d+)" 
| stats values(host) as host values(data_host) as data_host count last(_raw) as common_events last(_time) as _time max(line_length) as max_line_length by data_sourcetype log_level 
| table _time host data_host data_sourcetype log_level max_line_length count common_events 
| rename data_sourcetype as sourcetype 
| eval number=max_line_length 
| eval recommeneded_truncate=max_line_length+100000 
| eval recommeneded_truncate=recommeneded_truncate-(recommeneded_truncate%100000) 
| eval recommended_config="# props.conf
 ["+sourcetype+"]
 TRUNCATE = "+recommeneded_truncate 
| table _time host data_host sourcetype log_level max_line_length recommeneded_truncate recommended_config count common_events 
| sort -count
```
~ 2
```
index=_internal sourcetype=splunkd component=LineBreakingProcessor  
| extract 
| rex "because\slimit\sof\s(?<limit>\S+).*>=\s(?<actual>\S+)" 
| stats count avg(actual) max(actual)  dc(data_source) dc(data_host) BY data_sourcetype, limit 
| eval avg(actual)=round('avg(actual)') 
| sort - count
```
</details>

<details>
<summary><b>Data & Agent</b></summary>

Missing Forwarders (5 min = 900 sec)
```
| REST /services/deployment/server/clients
| eval difInSec=now()-lastPhoneHomeTime
| eval time=strftime(lastPhoneHomeTime,"%Y-%m-%d %H:%M:%S")
| search difInSec>900
| table hostname, ip, time
```

No Data from (Agent-Based and Agent-Less) Last 4 Days
```
| tstats latest(_time) as latest where index=* earliest=-4d by host index sourcetype
| eval recent = if(latest > relative_time(now(),"-360m"),"1","0"), LastReceiptTime = strftime(latest,"%c")
| where recent=0
| sort LastReceiptTime
| eval age=now()-latest
| eval age=round((age/60/60),1)
| eval age=age."hour"
| fields - recent latest
```

No Data Received from Windows Servers (Security Logs) Last 7 Days
```
| tstats latest(_time) as latest where index!="*_" earliest=-7d by host index source sourcetype
| search source="WinEventLog:Security"
| eval recent = if(latest > relative_time(now(),"-360m"),"1","0"), LastReceiptTime = strftime(latest,"%c")
| where recent=0
| sort LastReceiptTime
| eval age=now()-latest
| eval age=round((age/60/60),1)
| eval age=age."hour"
| fields - recent latest
```

</details>

<details>
<summary><b>Sourcetype missing in Datamodels </b></summary>
 
```
| tstats count WHERE index=* NOT index IN(sum_*, *summary, cim_*, es_*,splunkd* splunk_*) by sourcetype 
| fields - count 
| append 
[| datamodel 
| rex field=_raw "\"modelName\"\s*\:\s*\"(?<modelName>[^\"]+)\""
| fields modelName
| table modelName
| map maxsearches=40 search="tstats summariesonly=true count from datamodel=$modelName$ by sourcetype |eval modelName=\"$modelName$\""
]
| fillnull value="placeholder" modelName
| table modelName sourcetype count 
| fillnull value="nullfillerForNextCommand" count
| xyseries sourcetype modelName count
| addtotals
| fillnull value="not_in_DModel" Total
| table sourcetype Total *
| fields - "placeholder"
```
</details>

<details>
<summary><b>Check latest status of all modular inputs</b></summary> 

```
| rest /services/admin/inputstatus/ModularInputs:modular%20input%20commands splunk_server=local count=0 
| append [| rest /services/admin/inputstatus/ExecProcessor:exec%20commands splunk_server=local count=0] 
| fields inputs*
| transpose
| rex field=column "inputs(?<script>\S+)(?:\s\((?<stanza>[^\(]+)\))?\.(?<key>(exit status description)|(time closed)|(time opened))"
| eval value=coalesce('row 1', 'row 2'), stanza=coalesce(stanza, "default"), started=if(key=="time opened", value, started), stopped=if(key=="time closed", value, stopped)
| rex field=value "exited\s+with\s+code\s+(?<exit_status>\d+)"
| stats first(started) as started, first(stopped) as stopped, first(exit_status) as exit_status by script, stanza
| eval errmsg=case(exit_status=="0", null(), isnotnull(exit_status), "A script exited abnormally with exit status: "+exit_status, isnull(started) or isnotnull(stopped), "A script is in an unknown state"), ignore=if(`script_error_msg_ignore`, 1, 0)
```
</details>

<details>
<summary><b>Update Lookup File with New Entries and Deduplicate by Name</b></summary>

```
| inputlookup output.csv
| append [ <your search> ]
| dedup name
| outputlookup output.csv
```
</details>
