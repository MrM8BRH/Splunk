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
      <table>
        <title>Metadata information for hosts across all indexes.</title>
        <search>
          <query>| metadata type=hosts index=*
| eval firstTime=strftime(firstTime, "%Y-%m-%d %H:%M:%S"), lastTime=strftime(lastTime, "%Y-%m-%d %H:%M:%S"), recentTime=strftime(recentTime, "%Y-%m-%d %H:%M:%S")</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
        <option name="drilldown">none</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>List of Login Attempts to Splunk</title>
        <search>
          <query>index=_audit tag=authentication | stats count by user, info | sort - info</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
    <panel>
      <table>
        <title>List of Forwarders Installed</title>
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
      <chart>
        <title>Splunk users search activity</title>
        <search>
          <query>index=_audit splunk_server=local action=search (id=* OR search_id=*) 
| eval search_id = if(isnull(search_id), id, search_id) 
| replace '*' with * in search_id 
| rex "search='search\s(?&lt;search&gt;.*?)',\sautojoin" 
| search search_id!=scheduler_* 
| convert num(total_run_time) 
| eval user = if(user="n/a", null(), user) 
| stats min(_time) as _time first(user) as user max(total_run_time) as total_run_time first(search) as search by search_id 
| search search!=*_internal* search!=*_audit* 
| chart sum(total_run_time) as "Total search time" count as "Search count" max(_time) as "Last use" by user 
| fieldformat "Last use" = strftime('Last use', "%F %T.%Q")</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="charting.chart">pie</option>
        <option name="charting.drilldown">none</option>
      </chart>
    </panel>
    <panel>
      <chart>
        <title>Display disk space utilized by each app in splunk</title>
        <search>
          <query>index=_internal metrics kb group=per_sourcetype_thruput | eval sizeMB =
round(kb/1024,2)| stats sum(sizeMB) by series | sort -sum(sizeMB) | rename sum(sizeMB)
AS "Size on Disk (MB)"</query>
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
      <chart>
        <title>License usage by index</title>
        <search>
          <query>index=_internal source=*license_usage.log type="Usage" splunk_server=*
| eval Date=strftime(_time, "%Y/%m/%d")
| eventstats sum(b) as volume by idx, Date
| eval GB=round(volume/1024/1024/1024, 5) 
| chart first(GB) AS volume by idx | rename idx as index</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="charting.chart">column</option>
        <option name="charting.drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </chart>
    </panel>
    <panel>
      <chart>
        <title>DBSizeGB per Index</title>
        <search>
          <query>| rest /services/data/indexes 
| eval currentDBSizeGB = round(sum(currentDBSizeMB)/1024, 2) 
| stats sum(currentDBSizeGB) as totalDBSizeGB by title, splunk_server</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="charting.chart">column</option>
        <option name="charting.drilldown">none</option>
      </chart>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>Search History</title>
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
      <table>
        <title>Splunk errors in last 24 hours</title>
        <search>
          <query>index=_internal " error " NOT debug source=*splunkd.log*</query>
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
      <table>
        <title>Search Peer Not Responding</title>
        <search>
          <query>| rest splunk_server=local /services/search/distributed/peers/
| where status!="Up" AND disabled=0
| fields peerName, status
| rename peerName as Instance, status as Status</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>Find out all successful splunk configuration changes by user</title>
        <search>
          <query>index=_audit action=edit* info=granted operation!="list" host=* object=*
| transaction action user operation host maxspan=30s
| stats values(action) as action values(object) as modified_object by
_time,operation,user,host
| rename user as modified_by
| table _time action modified_object modified_by</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
        <option name="drilldown">none</option>
        <option name="refresh.display">progressbar</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <table>
        <title>Version of all apps and add-ons installed on Splunk</title>
        <search>
          <query>| rest /services/apps/local | search disabled=0 core=0|dedup label | table label version</query>
          <earliest>$field1.earliest$</earliest>
          <latest>$field1.latest$</latest>
        </search>
        <option name="drilldown">none</option>
      </table>
    </panel>
  </row>
</form>
```
</details>
