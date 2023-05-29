## External Links
[Splunk Use Cases](https://0xcybery.github.io/blog/Splunk+Use+Cases)

[GoSplunk](https://gosplunk.com/)

[Splunk Search Queries](https://github.com/secnnet/Splunk-Search-Queries)

[Platform Use Case Library](https://lantern.splunk.com/Splunk_Platform/Use_Cases)

[SplunkDashboards](https://github.com/Truvis/SplunkDashboards)

[Yuenx - Splunk](https://www.yuenx.com/?s=splunk)

[Regex v. Rex Commands in Splunk SPL](https://www.tekstream.com/blog/regex-v-rex-commands-in-splunk-spl/)

[Splunk Cheat Sheet: Search and Query Commands](https://www.stationx.net/splunk-cheat-sheet/)

## Windows Security Log Events

[Windows Security Log Events](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/default.aspx)

[Security Log Defined](https://system32.eventsentry.com/)

## Note
These queries are examples only and may need to be adjusted to 
fit your specific use case and data sources. Additionally, they assume that the relevant logs are being ingested into Splunk and are searchable using the specified index or sourcetype.

## Splunk Queries
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
## Threat Hunting with Splunk
Username guessing brute force attack
```
index="your index name here" sourcetype=windows EventCode=4625 OR EventCode=4624 
| bin _time span=5m as minute 
| rex "Security ID:\s*\w*\s*\w*\s*Account Name:\s*(?<username>.*)\s*Account Domain:" 
| stats count(Keywords) as Attempts,
count(eval(match(Keywords,"Audit Failure"))) as Failed,
count(eval(match(Keywords,"Audit Success"))) as Success by minute username
| where Failed>=4
| stats dc(username) as Total by minute 
| where Total>5
```
AD Password Change Attempts
```
index="your index name here" source="WinEventLog:Security" "EventCode=4723" src_user!="*$" src_user!="_svc_*" 
| eval daynumber=strftime(_time,"%Y-%m-%d") 
| chart count by daynumber, status 
| eval daynumber = mvindex(split(daynumber,"-"),2)
```
Find Passwords Entered As Usernames
```
index="your index name here" source=WinEventLog:Security TaskCategory=Logon Keywords="Audit Failure" 
| eval password=if(match(User_Name, "^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[\W])(?=.{10,})"), "Yes", "No") 
| stats count by password User_Name 
| search password=Yes
```
Failed Attempt to Login To A Disabled Account
```
index="your index name here" source="WinEventLog:security" EventCode=4625 (Sub_Status="0xc0000072" OR Sub_Status="0xC0000072") Security_ID!="NULL SID" Account_Name!="*$" 
| eval Date=strftime(_time, "%Y/%m/%d")
| rex "Which\sLogon\sFailed:\s+\S+\s\S+\s+\S+\s+Account\sName:\s+(?<facct>\S+)" 
| eval Date=strftime(_time, "%Y/%m/%d") 
| stats count by Date, facct, host, Keywords 
| rename facct as "Target Account" host as "Host" Keywords as "Status" count as “Count”
```
Changes to Windows User Group by Account
```
index="your index name here" sourcetype=WinEventLog:Security (EventCode=4728 OR EventCode=4732 OR EventCode=4746 OR EventCode=4751 OR EventCode=4756 OR EventCode=4161 OR EventCode=4185) 
| eval Date=strftime(_time, "%Y/%m/%d") 
| rex "Member:\s+\w+\s\w+:.*\\\(?<TargetAccount>.*)" 
| rex "Account\sName:\s+(?<SourceAccount>.*)" 
| stats count by Date, TargetAccount, SourceAccount, Group_Name, host, Keywords 
| sort - Date 
| rename SourceAccount as "Administrator Account" 
| rename TargetAccount as “Target Account”
```
Privilege Escalation Detection
```
index="your index name here" sourcetype="WinEventLog:Security" (EventCode=576 OR EventCode=4672 OR EventCode=577 OR EventCode=4673 OR EventCode=578 OR EventCode=4674) 
| stats count by user
```
File Deletion Attempts
```
index="your index name here" sourcetype="WinEventLog:Security" EventCode=564 
| eval Date=strftime(_time, "%Y/%m/%d") 
| stats count by Date, Image_File_Name, Type, host 
| sort - Date
```
Query to identify the top 10 hosts with the highest number of security events:
```
 index=<index_name> sourcetype=<sourcetype> earliest=-7d latest=now
| stats count by host
| sort -count
| head 10
```
Query to identify the top 10 users with the most failed login attempts:
```
index=<index_name> sourcetype=<sourcetype> earliest=-7d latest=now EventCode=4625
| stats count by user
| sort -count
| head 10
```
Query to identify the top 10 countries with the most traffic to your network:
```
index=<index_name> sourcetype=<sourcetype> earliest=-7d latest=now
| iplocation src_ip
| stats count by Country
| sort -count
| head 10
```
Query to identify the top 10 destination IP addresses with the most traffic:
```
index=<index_name> sourcetype=<sourcetype> earliest=-7d latest=now
| stats count by dest_ip
| sort -count
| head 10
```
Query to identify the most common attack methods:
```
index=<index_name> sourcetype=<sourcetype> earliest=-7d latest=now
| top attack_method
```
PowerShell commands executed
```
index=* source=WinEventlog:Microsoft-Windows-Sysmon/Operational CommandLine="*powershell*"
dedup CommandLine | Table ParentCommandLine CommandLine
```
PowerShell execution policy is set to Bypass
```
index="windows" sourcetype=WinRegistry key_path="HKLM\\software\\microsoft\\powershell\\1\\shellids\\microsoft.powershell\\executionpolicy"
| table _time, host, registry_type, registry_value_data, registry_value_name
| rename host as Host, registry_type as Action, registry_value_data as "Registry Value", registry_value_name as “Registry Value Name” 
```
Potential Suspicious Activity in Windows
```
index=* sourcetype="WinEventLog:Security" EventCode=4688 NOT (Account_Name=*$) (arp.exe OR at.exe OR bcdedit.exe OR bcp.exe OR chcp.exe OR cmd.exe OR cscript.exe OR csvde OR dsquery.exe OR ipconfig.exe OR mimikatz.exe OR nbtstat.exe OR nc.exe OR netcat.exe OR netstat.exe OR nmap OR nslookup.exe OR netsh OR OSQL.exe OR ping.exe OR powershell.exe OR powercat.ps1 OR psexec.exe OR psexecsvc.exe OR psLoggedOn.exe OR procdump.exe OR qprocess.exe OR query.exe OR rar.exe OR reg.exe OR route.exe OR runas.exe OR rundll32 OR schtasks.exe OR sethc.exe OR sqlcmd.exe OR sc.exe OR ssh.exe OR sysprep.exe OR systeminfo.exe OR system32\\net.exe OR reg.exe OR tasklist.exe OR tracert.exe OR vssadmin.exe OR whoami.exe OR winrar.exe OR wscript.exe OR "winrm.*" OR "winrs.*" OR wmic.exe OR wsmprovhost.exe OR wusa.exe) | eval Message=split(Message,".") | eval Short_Message=mvindex(Message,0) | table _time, host, Account_Name, Process_Name, Process_ID, Process_Command_Line, New_Process_Name, New_Process_ID, Creator_Process_ID, Short_Message
```
