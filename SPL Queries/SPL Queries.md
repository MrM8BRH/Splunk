## Windows Security Log Events
[Windows Event Log Analysis](https://cybersecuritynews.com/windows-event-log-analysis/)

[Security Log Defined](https://system32.eventsentry.com/)

[Windows Security Log Events](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/default.aspx)

## External Links

[Splunk Use Cases](https://0xcybery.github.io/blog/Splunk+Use+Cases)

[GoSplunk](https://gosplunk.com/)

[Splunk Search Queries](https://github.com/secnnet/Splunk-Search-Queries)

[Splunk ES Queries](https://github.com/shauntdergrigorian/splunkqueries)

[Some Threat Hunting queries useful for blue teamers](https://github.com/BankSecurity/Threat_Hunting)

[A list of Splunk queries that I've collected and used over time](https://github.com/shauntdergrigorian/splunkqueries)

[Platform Use Case Library](https://lantern.splunk.com/Splunk_Platform/Use_Cases)

[SplunkDashboards](https://github.com/Truvis/SplunkDashboards)

[Yuenx - Splunk](https://www.yuenx.com/?s=splunk)

[Regex v. Rex Commands in Splunk SPL](https://www.tekstream.com/blog/regex-v-rex-commands-in-splunk-spl/)

[Splunk Cheat Sheet: Search and Query Commands](https://www.stationx.net/splunk-cheat-sheet/)

## Splunk Queries
To display a list of fields for an index
```
index="your index name here" | fieldsummary | table field
```
List of Login attempts of splunk local users
```
index=_audit action="login attempt"
| stats count by user info action _time
| sort - info
```
License usage by index
```
index=_internal source=*license_usage.log type="Usage" splunk_server=* 
| eval Date=strftime(_time, "%Y/%m/%d") 
| eventstats sum(b) as volume by idx, Date 
| veil MB=round(volume/1024/1024,5) 
| timechart first(MB) AS volume by idx
```
List of Forwarders Installed
```
index="_internal" sourcetype=splunkd group=tcpin_connections NOT eventType=* 
| eval Hostname=if(isnull(hostname), sourceHost,hostname),version=if(isnull(version),"pre 4.2",version),architecture=if(isnull(arch),"n/a",arch) 
| stats count by Hostname version architecture 
| sort + version
```
Splunk users search activity
```
index=_audit splunk_server=local action=search (id=* OR search_id=*) 
| eval search_id = if(isnull(search_id), id, search_id) 
| replace '*' with * in search_id 
| rex "search='search\s(?<search>.*?)',\sautojoin" 
| search search_id!=scheduler_* 
| convert num(total_run_time) 
| eval user = if(user="n/a", null(), user) 
| stats min(_time) as _time first(user) as user max(total_run_time) as total_run_time first(search) as search by search_id 
| search search!=*_internal* search!=*_audit* 
| chart sum(total_run_time) as "Total search time" count as "Search count" max(_time) as "Last use" by user 
| fieldformat "Last use" = strftime('Last use', "%F %T.%Q")
```
Search History
```
index=_audit action=search sourcetype=audittrail search_id=* NOT (user=splunk-system-user) search!="'typeahead*"
| rex "search\=\'(search|\s+)\s(?P<search>[\n\S\s]+?(?=\'))"
| rex field=search "sourcetype\s*=\s*\"*(?<SourcetypeUsed>[^\s\"]+)" 
| rex field=search "index\s*=\s*\"*(?<IndexUsed>[^\s\"]+)"
| stats latest(_time) as Latest by user search SourcetypeUsed IndexUsed
| convert ctime(Latest)
```
