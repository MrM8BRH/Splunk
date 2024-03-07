## Windows Security Log Events
[Windows Event Log Analysis](https://cybersecuritynews.com/windows-event-log-analysis/)

[Security Log Defined](https://system32.eventsentry.com/)

[Windows Security Log Events](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/default.aspx)

[Windows Security Events You Should Monitor](https://medium.com/@alizourob4/windows-security-events-you-should-monitor-eebb7a034bbf)

## External Links

[Security Content](https://research.splunk.com/tags/)

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

## Splunk Dashboard
Author: [MrM8BRH](https://github.com/MrM8BRH)

<details>
 
 <summary>Source Code</summary>
 
```
<form version="1.1" theme="dark">
  <label>Splunk Dashboard</label>
  <fieldset submitButton="true" autoRun="true">
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
      <title>Metadata information for hosts across all indexes.</title>
      <table>
        <search>
          <query>| metadata type=hosts index=*
| eval firstTime=strftime(firstTime, "%Y-%m-%d %H:%M:%S"), lastTime=strftime(lastTime, "%Y-%m-%d %H:%M:%S"), recentTime=strftime(recentTime, "%Y-%m-%d %H:%M:%S")</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
    <panel>
      <title>List of Forwarders Installed.</title>
      <table>
        <search>
          <query>index="_internal" sourcetype=splunkd group=tcpin_connections NOT eventType=* 
| eval Hostname=if(isnull(hostname), sourceHost,hostname),version=if(isnull(version),"pre 4.2",version),architecture=if(isnull(arch),"n/a",arch) 
| stats count by Hostname version architecture 
| sort + version</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <title>List of Login Attempts to Splunk.</title>
      <table>
        <search>
          <query>index=_audit tag=authentication | eval time=strftime(_time,"%Y-%m-%d %H:%M:%S") | stats count by time, user, info | sort - info | rename time as Time, user as User, info as Action</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
    <panel>
      <title>Host not sending logs for x days.</title>
      <table>
        <search>
          <query>| tstats count as countAtToday latest(_time) as lastTime where index!="*_" by host sourcetype index 
| eval age=now()-lastTime 
| sort age d 
| fieldformat lastTime=strftime(lastTime,"%Y/%m/%d %H:%M:%S") 
| eval age=round((age/60/60),1) 
| search age&gt;=48 
| eval age=age."hour" 
| dedup host</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <title>Data Indexed in GB for Last 7 days per Indexer.</title>
      <table>
        <search>
          <query>index=_internal source=*license_usage.log type="RolloverSummary" | eval _time=_time - 43200 | bin _time span=1d | eval GB=round(b/1024/1024/1024, 3) | stats sum(GB) by host _time | sort -_time</query>
          <earliest>-7d@h</earliest>
          <latest>now</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
    <panel>
      <title>License usage by index.</title>
      <chart>
        <search>
          <query>index=_internal source=*license_usage.log type="Usage" splunk_server=*
| eval Date=strftime(_time, "%Y/%m/%d")
| eventstats sum(b) as volume by idx, Date
| eval GB=round(volume/1024/1024/1024, 5) 
| chart first(GB) AS volume by idx | rename idx as index</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="charting.chart">pie</option>
        <option name="charting.drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </chart>
    </panel>
  </row>
  <row>
    <panel>
      <title>Find out all successful splunk configuration changes by user.</title>
      <table>
        <search>
          <query>index=_audit action=edit* info=granted operation!="list" host=* object=*
| top limit=10 user
| transaction action user operation host maxspan=30s
| stats values(action) as action values(object) as modified_object by
_time,operation,user,host
| rename user as modified_by
| table _time action modified_object modified_by</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
    <panel>
      <title>Splunk errors in last 24 hours.</title>
      <table>
        <search>
          <query>index=_internal " error " NOT debug source=*splunkd.log* | top limit=10 _raw</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <title>Identifying Hosts not sending data for more than 6 hours.</title>
      <table>
        <search>
          <query>| tstats latest(_time) as latest where index!="*_" earliest=-9h by host index sourcetype
| eval recent = if(latest &gt; relative_time(now(),"-360m"),"1","0"), LastReceiptTime = strftime(latest,"%c")
| where recent=0
| sort LastReceiptTime
| eval age=now()-latest
| eval age=round((age/60/60),1)
| eval age=age."hour"
| fields - recent latest</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
    <panel>
      <title>Show Searches with Details (Who | When | What).</title>
      <table>
        <search>
          <query>index=_audit action=search sourcetype=audittrail search_id=* NOT (user=splunk-system-user) search!="'typeahead*"
| rex "search\=\'(search|\s+)\s(?P&lt;search&gt;[\n\S\s]+?(?=\'))"
| rex field=search "sourcetype\s*=\s*\"*(?&lt;SourcetypeUsed&gt;[^\s\"]+)" 
| rex field=search "index\s*=\s*\"*(?&lt;IndexUsed&gt;[^\s\"]+)"
| stats latest(_time) as Latest by user search SourcetypeUsed IndexUsed
| convert ctime(Latest)</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <title>Who is using Splunk by user, app and view.</title>
      <table>
        <search>
          <query>index=_internal sourcetype="splunk_web_access" method="GET" status="200" user!=-
| stats count latest(_time) as ViewTime by user app view
| sort -count
| eventstats sum(count) as countByApp list(view) as view list(count) as count list(ViewTime) as ViewTime by user app
| convert timeformat="%a %m/%d/%Y %I:%M:%S %p" ctime(ViewTime)
| dedup app
| appendpipe [stats sum(count) as count by user | eval view = "Total Views"]
| sort + user -countByApp</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <title>Skipped searches and why.</title>
      <table>
        <search>
          <query>index = _internal skipped sourcetype=scheduler status=skipped
| stats count by app search_type reason savedsearch_name 
| sort -count</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
</form>
```
</details>

---

Splunk query to find truncation issues and also recommend a TRUNCATE parameter for props.conf.
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

Splunk query to list all sourcetypes
```
| metadata type=sourcetypes index=*
```

To see where what you are collecting data from (extend this to 7 days or something)
```
| tstats latest(_time) as latest_indexed WHERE index=* by host
```

Convert epoch time to a human readable time
```
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
```

Check latest status of all modular inputs
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
