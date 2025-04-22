## Windows Security Log Events
- [Eventlog Compendium](https://eventlog-compendium.streamlit.app/)
- [Windows Security Log Events](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/default.aspx)
- [Windows security encyclopedia](https://www.windows-security.org/windows-event-ids)
- [Windows Event Log Analysis](https://cybersecuritynews.com/windows-event-log-analysis/)
- [Security Log Defined](https://system32.eventsentry.com/)

## Resources
- [Security Content](https://research.splunk.com/detections/)
- [Splunk Use Cases](https://0xcybery.github.io/blog/Splunk+Use+Cases)
- [GoSplunk](https://gosplunk.com/)
- [Splunk ES Queries](https://github.com/shauntdergrigorian/splunkqueries)

[ITOps](https://lantern.splunk.com/Observability/UCE/Foundational_Visibility/IT_Ops)

<details>
<summary><b>Active Directory</b></summary>

#### Windows Event Logs

AD - Group and Membership Changes
```
index=wineventlog source="WinEventLog:Security" (EventCode=4728 OR EventCode=4729)  Group_Name="*"
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| rename time AS Time src_user AS "Actioned By" user AS User  name as "Action Taken" Group_Name AS "Group Name" Account_Domain AS "Account Domain"
| table Time "Actioned By" User "Action Taken" "Group Name" "Account Domain"
```
AD - Clearing of Windows Audit Logs 
```
index=wineventlog source="WinEventLog:Security" (EventCode=1102 OR EventCode=517) 
| eval Date=strftime(_time, "%Y/%m/%d") 
| stats count by Client_User_Name, host, index, Date 
| sort - Date 
| rename Client_User_Name as "Account Name"
```
AD - Console logins
```
index=wineventlog source="WinEventLog:Security" EventCode=4624 Logon_Type=2 
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| rename time AS Time host AS Host user AS User dvc AS Device action AS Action
| table Time Host User Device Action
| dedup Time Host User Device Action
```
AD - Installed Applications
```
index=windows sourcetype="Script:InstalledApps" 
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| rename time AS Time host AS Host 
| table Time,Host,DisplayName,Publisher,InstallSource,InstallDate
| sort Host
```
AD - Local Admin Account
```
index=wineventlog source="WinEventLog:Security" EventCode=4732 Group_Name=Administrators
| table _time,ComputerName,Group_Name,Account_Name,Message
```
AD - Failed Logins for Disabled Accounts
```
index=wineventlog source="WinEventLog:Security" EventCode=4625 Sub_Status="0xC0000072"
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| rename time AS Time host AS Host app AS Application src AS User src_ip AS "Source IP" dest AS Destination name AS Description
| table Time,Host,Application,User,"Source IP",Destination,Description
```
AD - Password Never Expires
```
index=wineventlog source="WinEventLog:Security" EventCode=4738 MSADChangedAttributes="*'Don't Expire Password' - Disabled*" OR MSADChangedAttributes="*'Don't Expire Password' - Enabled*"
| eval time = strftime(_time,"%c") 
| table time,host,name,user,src_user,dest,MSADChangedAttributes
| rename time as "Time" , name as "Action" , user as "User" , src_user as "Actioned By", dest as "Destination", host as "Hostname"
```
AD - Detect Windows Account Privilege Changes
```
index=wineventlog source="WinEventLog:Security" (EventCode=4672 OR EventCode=4673) user!="*$" name="Special privileges assigned to new logon" 
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| rename time AS Time host AS Host user AS User app AS Application action AS Action 
| table Time,Host,User,Application,Action,Privileges
```
AD - A Member was Added/Removed from Domain Admin Group
```
index=wineventlog source="WinEventLog:Security" EventCode=4728 OR EventCode=4729 Group_Name="Domain Admins" 
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| table time,host,name,user,src_user,Group_Name 
| rename time as "Time" , name as "Action" , user as "User" ,src_user as "Actioned By", host as "Hostname", Group_Name as "Group Name"
```
AD - A user Account was Created/Deleted
```
index=wineventlog source="WinEventLog:Security" EventCode=4720 OR EventCode=4726
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| table time,host,name,user,src_user 
| rename time as "Time" , name as "Action" , user as "User" ,src_user as "Actioned By",host as "Hostname"
```
AD - A user Account was Enabled/Disabled
```
index=wineventlog source="WinEventLog:Security" EventCode=4725 OR EventCode=4722 user!=*$ 
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| table time,host,name,user,src_user 
| rename time as "Time" , name as "Action" , user as "User" ,src_user as "Actioned By", host as "Hostname"
```
AD - RDP Connections
```
index=wineventlog source="WinEventLog:Security" Logon_Type=10 ((EventCode=4624 OR EventCode=528) OR (EventCode=4625 OR EventCode=529))
| eval action=CASE(EventCode=4624 OR EventCode=528, "Success", EventCode=4625 OR EventCode=529, "Failure")
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| table time, user, src_user, src_ip, dest,action
| rename time AS Time user AS User src AS Source dest AS Destination action AS Action src_user AS "Source User" src_ip AS "IP Address"
```
AD - User Account Locked/Unlocked
```
index="wineventlog" source="WinEventLog:Security" signature="A user account was locked out" OR signature="A user account was unlocked" 
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| table time,host,user,name,src_user
| rename time as "Time" , name as "Action" , src_user as "Actioned By", host AS Host, user AS User
```
AD - User Account Changed (Password_Last_Set)
```
index="wineventlog" source="WinEventLog:Security" signature="A user account was changed" 
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| table time,host,user,name,src_user,Password_Last_Set
| rename time as "Time" , name as "Action" , user as "User" , src_user as "Actioned By" , host AS Host
```
AD - Domain Policy Changed/Reset Passowrd
```
index="wineventlog" source="WinEventLog:Security" signature="An attempt was made to change an account's password" OR signature="An attempt was made to reset an accounts password" 
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S")
| table time,host,user,name,src_user 
| rename time as "Time" , name as "Action" , user as "User" , src_user as "Actioned By" , host AS Host
```

AD - Windows Security Daily Domain Activities
```
index=wineventlog source=WinEventLog:Security src_nt_domain!="NT AUTHORITY" EventCode=4720 OR EventCode=4726 OR EventCode=4738 OR EventCode=4767 OR EventCode=4781 OR EventCode=4727 OR EventCode=4730 OR EventCode=4731 OR EventCode=4734 OR EventCode=4735 OR EventCode=4737 OR EventCode=4744 OR EventCode=4745 OR EventCode=4748 OR EventCode=4749 OR EventCode=4750 OR EventCode=4753 OR EventCode=4754 OR EventCode=4755 OR EventCode=4758 OR EventCode=4759 OR EventCode=4760 OR EventCode=4763 OR EventCode=4764 OR EventCode=4728 OR EventCode=4729 OR EventCode=4732 OR EventCode=4733 OR EventCode=4746 OR EventCode=4747 OR EventCode=4751 OR EventCode=4752 OR EventCode=4756 OR EventCode=4757 OR EventCode=4761 OR EventCode=4762
| rex field=member_id "^\w+\W(?<ITS_Admin>\w*\s\w*\s\w*|\w+_\w+|\w*\s\w*|\w*)(\s\w+\W|\s)(?<Target_Account>.*\S)"
| eval Target_Account=if(Target_Account="NONE_MAPPED", trim(member_dn, ITS_Admin), Target_Account)
| table _time, EventCode, src_nt_domain, ITS_Admin, Target_Account,src_nt_domain,msad_action,Group_Name,MSADChangedAttributes
| sort MSADChangedAttributes,ITS_Admin, Target_Account
| rename ITS_Admin as "ITS Admin", src_nt_domain as "Source Domain"
```

AD - Potential Suspicious Activity
```
index=wineventlog source="WinEventLog:Security" Account_Name!="SplunkForwarder" EventCode=4688 NOT (Account_Name=*$) (arp.exe OR at.exe OR bcdedit.exe OR bcp.exe OR chcp.exe OR cmd.exe OR cscript.exe OR csvde OR dsquery.exe OR ipconfig.exe OR mimikatz.exe OR nbtstat.exe OR nc.exe OR netcat.exe OR netstat.exe OR nmap OR nslookup.exe OR netsh OR OSQL.exe OR ping.exe OR powershell.exe OR powercat.ps1 OR psexec.exe OR psexecsvc.exe OR psLoggedOn.exe OR procdump.exe OR qprocess.exe OR query.exe OR rar.exe OR reg.exe OR route.exe OR runas.exe OR rundll32 OR schtasks.exe OR sethc.exe OR sqlcmd.exe OR sc.exe OR ssh.exe OR sysprep.exe OR systeminfo.exe OR system32\\net.exe OR reg.exe OR tasklist.exe OR tracert.exe OR vssadmin.exe OR whoami.exe OR winrar.exe OR wscript.exe OR "winrm.*" OR "winrs.*" OR wmic.exe OR wsmprovhost.exe OR wusa.exe) 
| eval Message=split(Message,".") 
| eval Short_Message=mvindex(Message,0) 
| table _time, host, Account_Name, New_Process_Name, New_Process_ID, Creator_Process_ID, Short_Message
```

AD - List All Successful Logins by Account Name
```
index=wineventlog source="WinEventLog:security" (Logon_Type=2 OR Logon_Type=7 OR Logon_Type=10) (EventCode=528 OR EventCode=540 OR EventCode=4624) | rex "New\sLogon:\s+.*\s+Account\sName:\s+(?<UserName>\S+)" | eval Account=coalesce(User_Name,UserName) | stats count by Account | sort - count
```

AD - Accounts Deleted within 24 Hours of Creation 
```
index=wineventlog source=WinEventLog:Security (EventCode=4726 OR EventCode=4720) 
| eval Date=strftime(_time, "%Y/%m/%d") 
| rex "Subject:\s+\w+\s\S+\s+\S+\s+\w+\s\w+:\s+(?<SourceAccount>\S+)" 
| rex "Target\s\w+:\s+\w+\s\w+:\s+\S+\s+\w+\s\w+:\s+(?<DeletedAccount>\S+)" 
| rex "New\s\w+:\s+\w+\s\w+:\s+\S+\s+\w+\s\w+:\s+(?<NewAccount>\S+)" 
| eval SuspectAccount=coalesce(DeletedAccount,NewAccount) 
| transaction SuspectAccount startswith="EventCode=4720" endswith="EventCode=4726" 
|eval duration=round(((duration/60)/60)/24, 2) 
| eval Age=case(duration<=1, "Critical", duration>1 AND duration<=7, "Warning", duration>7, "Normal")
| table Date, index, host, SourceAccount, SuspectAccount, duration, Age 
| rename duration as "Days Account was Active" 
| sort + "Days Account was Active"
```

AD - Password Non Compliance
```
index=wineventlog source="WinEventLog:Security" EventCode=4723  Keywords="Audit Failure" 
| eval Date=strftime(_time, "%Y/%m/%d") 
| rex "Target\sAccount:\s+Security\sID:.*\\\(?<account>\S+)" 
| stats count by Date, account, host 
| sort - Date
```

AD - Modification to File Permissions
```
index=wineventlog source="WinEventLog:Security" EventCode=4670 (Security_ID!="NT AUTHORITY*") (Security_ID!="S-*")
| eval Date=strftime(_time, "%Y/%m/%d")
| stats count by Date, Account_Name, Process_Name, Keywords, host
| sort - Date
```

AD -  Failed Authentication to Non-existing Accounts 
```
index=wineventlog source="WinEventLog:Security" EventCode=4625 Sub_Status=0xC0000064 
| eval Date=strftime(_time, "%Y/%m/%d") 
| rex "Which\sLogon\sFailed:\s+Security\sID:\s+\S.*\s+\w+\s\w+\S\s.(?<uacct>\S.*)" 
| stats count by Date, uacct, host 
| rename count as "Attempts" 
| sort - Attempts
```

AD - System Time Modifications
```
index=wineventlog source="WinEventLog:Security" EventCode=4616 (NOT Account_Name="*$") (NOT Account_Name="LOCAL SERVICE")
| eval Date=strftime(_time, "%Y/%m/%d %H:%M:%S")
| eval oldtime = strptime(replace(Previous_Time, "\D", ""), "%Y%m%d%H%M%S%9N") 
| eval t=_time 
| rename t as "eventtime" 
| eval diff=round(((eventtime-oldtime)/60)/60,2) 
| where diff!=0
| stats count by host, Account_Name, diff, Date 
| sort - Date
| rename diff as "Hours Between New Time and Actual Time" 
|rename Account_Name as "Source Account" 
| rename host as "Target Machine"
|rename Date as "Date and Time"
| fields - count
```

AD - User Logon / Session Duration 
```
index=wineventlog source=WinEventLog:Security (EventCode=4624 OR EventCode=4634) (Logon_Type=2 OR Logon_Type=10) 
| eval Date=strftime(_time, "%Y/%m/%d")
| eval LogonType=case(Logon_Type="2", "Local Console Access", Logon_Type="10", "Remote Desktop via Terminal Services")
| transaction host user startswith=EventCode=4624 endswith=EventCode=4634 | where duration > 5 | eval duration = duration/60 
| eval duration=round(duration,2)
| table host, user, LogonType duration, Date 
| rename duration as "Session Duration in Minutes" 
| sort - date
```

AD - Password Changes by User Account
```
index=wineventlog source="WinEventLog:Security" (EventCode=628 OR EventCode=627 OR EventCode=4723 OR EventCode=4724) 
| chart count by user
```

#### LDAP Queries
AD - Dormant Account
```
| ldapsearch domain=default search="(&(objectclass=user)(!(objectClass=computer)))" limit=0 attrs="sAMAccountName, displayName, distinguishedName, userAccountControl, whenCreated, accountExpires, lastLogonTimestamp"
| makemv userAccountControl
| search dn!="*OU=_Disabled Users*" userAccountControl!="*ACCOUNTDISABLE*"
| eval lastLoginAge_epoch=strptime(lastLogonTimestamp, "%Y-%m-%dT%H:%M:%S")
| eval lastLoginAge=round((lastLoginAge_epoch - now())/86400, 0)
| where lastLoginAge < -90
| table sAMAccountName, displayName, dn, userAccountControl, whenCreated, lastLoginAge, lastLogonTimestamp, accountExpires
```

AD - Passwords Never Changed
```
| ldapsearch domain=default search="(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2))(userAccountControl:1.2.840.113556.1.4.803:=65536))" attrs="sAMAccountName,pwdLastSet" 
| table sAMAccountName, dn, pwdLastSet
```

AD - Passwords Last Changed
```
| ldapsearch domain="default" search="(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" attrs="sAMAccountName,pwdLastSet"
| table sAMAccountName, dn, pwdLastSet
```

AD - Check for Disabled User Accounts
```
| ldapsearch domain="default" search="(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=2))" attrs="sAMAccountName"
| table sAMAccountName, dn
```

</details>

<details>
<summary><b>Linux</b></summary>

Linux - SSH Logins
```
index=linux "Accepted Publickey" OR "session opened" OR "Accepted password" src!="PAM_IP_ADDR" src!="" user!=""
| table _time,user,src,dest,src_port,sshd_protocol,action
```

Linux - SSH Logins (Syslog - SC4S)
```
index=osnix source="program:sshd" "Accepted Publickey" OR "session opened" _raw!="*PAM_IP_ADDR*" 
| table _time,host,sc4s_fromhostip,user 
| dedup _time,host,user | sort -_time
```

Linux - Console logins
```
index=osnix OR index=linux "Started Session 7 of" 
| table _time,host,_raw
```

Linux - Repeated Unsuccessful Logon Attempts
```
index=linux sourcetype=linux_secure
| eval Date=strftime(_time, "%Y/%m/%d")
| rex ".*:\d{2}\s(?<hostname>\S+)"
| rex "gdm\S+\sauthentication\s(?<status>\w+)"
| rex "\suser[^'](?<User>\S+\w+)"
| search status=failure| stats count as fails by Date, User, hostname
| eval "Alert Level"=case(fails>=50, "Critical", fails<50 AND fails>=20, "Warning", fails<20, "Normal")
| sort - fails| rename fails as "Failed Logon Attempts"
| rename User as "Account in Question"
```

Linux - Top 10 Most Active Hosts
```
index=linux sourcetype=linux_secure 
| rex ".*:\d{2}\s(?<hostname>\S+)"
| top limit=10 hostname
```

Linux - Top 10 Most Active Users
```
index=linux sourcetype=linux_secure 
| rex "\suser[^'](?<User>\S+\w+)" 
| top limit=10 User
```

Linux - List of Users
```
index=linux sourcetype=linux_secure 
| rex "\suser[^'](?<User>\S+\w+)" 
| stats count by User
```
</details>


<details>
<summary><b>Appian</b></summary>

Appian - Admin Console
```
index=appian source="*admin_console.csv"
| table _time,Property,Count
```
Appian - Blocked Files
```
index=appian source="*blocked_files.csv*"
| table _time,User,"Document Name",Reason,Details,Hash
```
Appian - Data Store Deletions
```
index=appian source="*data_store_deletions*"
| table _time,"Data Store",Entity,Id,"Node Display Name",User
```
Appian - Decryption
```
index=appian source="*decryption.csv*"
| table _time,Username,Context,Action,Success
```
Appian - DevOps Infrastructure
```
index=appian source="*devops_infrastructure.csv"
| table _time,ID,Name,URL,"Last Action Username","Last Action Type","Last Action Name","Last Action IP","Last Action Date","Remote Enabled"
```
Appian - Devops Infrastructure Handler
```
index=appian source="*devops_infrastructure_handler.csv"
| table ID,Name,URL,"IP Address","Status Code","Error Occurred","Direction","Before or After Request Processed"
```
Appian - File Attachment Downloads
```
index=appian source="*file_attachment_downloads.csv*" "File name"!="*.png" "File name"!="*.ico" "File name"!="*.jpg"
| table _time,User,"File name","Download Successful"
```
Appian - Login Audit
```
index=appian source="*login-audit.csv" API_USER!="API-USER"
| table _time,API_USER,"Web API",Succeeded
| rename API_USER as "User" , Succeeded as "Action"
```
Appian - Object Rolemap Audit
```
index=appian source="*object_rolemap_audit.csv"
| table _time,Username,Name,Type,"Previous Rolemap","New Rolemap"
```
Appian - Records Usage
```
index=appian source="*records_usage.csv*"
| table _time,User,View,"Record Type Name",Action
```
Appian - Removed Processes
```
index=appian source="*removed*"
| table _time,Action,"Process ID","Process Name","Transaction ID",Username
```
Appian - Sites Usage
```
index=appian source="*sites_usage.csv*"
| table _time,User,Site,Page,Action
```
Appian - Users
```
index=appian source="*users.csv"
| table _time,"Active LDAP Users","Active SAML Users","Active System Administrators","Active Tempo Users","Active Users","Total Users"
```
Appian - User Management
```
index=appian source="*user_management.csv"
| search Action!="Log Initialized"
| table _time,Action,"Modified By Username",Username,"Original Value","New Value"
```

</details>

<details>
<summary><b>CrowdStrike</b></summary>

CrowdStrike - Logins
```
index=crowdstrike user!="" action!=""
| table _time,user,event.ServiceName,action
```
CrowdStrike FW - RDP Sessions
```
index=crowdstrike rdp event.LocalAddress!="PAM_IP_ADDR" 
| table _time,event.HostName,event.LocalAddress,event.RemoteAddress,event.PolicyName,event.RuleGroupName,event.RuleAction
```
CrowdStrike - Malware Detections
```
index="crowdstrike" "metadata.eventType"=DetectionSummaryEvent metadata.customerIDString=* event.DetectId!="" 
| table _time,action,description,event.ComputerName,event.DetectName,event.FileName,event.FilePath,event.IOCType,event.IOCValue,event.LocalIP,event.MACAddress,event.Objective,event.SeverityName,event.Tactic,event.Technique,event.UserName,event.CommandLine,event.AssociatedFile
```
CrowdStrike - Policies
```
index=crowdstrike "metadata.eventType"=UserActivityAuditEvent
| search "event.OperationName"=*policy 
| table _time,*OperationName,*ServiceName,*UserId,*UserIp,*policy_name,*policy_enabled
```
CrowdStrike - FileVantage
```
index="crowdstrike" source=crowdstrike_filevantage_json
| table _time,entity_type,severity,action_type,action_timestamp,command_line,entity_path,grandparent_process_image_file_name,parent_process_image_file_name,host.name,host.local_ip,host.os_version,policy.name,policy.rule_group.name
```
CrowdStrike - Identities
```
index=crowdstrike sourcetype="crowdstrike:identities" riskScoreSeverity="HIGH" 
| table _time,primaryDisplayName,isHuman,isProgrammatic,emailAddresses{},accounts{}.userAccountControl,accounts{}.title,accounts{}.samAccountName,accounts{}.ou,accounts{}.enabled,accounts{}.dn,accounts{}.dataSource,accounts{}.department,accounts{}.description,type,roles{}.type,riskScoreSeverity,riskFactors{}.type,riskFactors{}.severity
```
CrowdStrike - Event Streams
```
index=crowdstrike sourcetype="CrowdStrike:Event:Streams:JSON" 
| table _time,ta_*,metadata.eventType,event.UserIp,event.Source,event.SourceIp,event.OperationName,event.Attributes.scopes,event.Attributes.produces,action
```
</details>

<details>
<summary><b>F5 BIG-IP</b></summary>

F5 - Admin Actions
```
index=netops sourcetype="f5:bigip:syslog" AUDIT AND object AND admin
| table _time,_raw
```
F5 - Blocked Multi-Severity Attack Incidents
```
index=netwaf severity="Critical" OR severity="High" OR severity="Medium" AND  request_status="blocked" 
| table table _time,attack_type,dest_port,method,policy_name,request_status,geo_location,severity,sig_cves,uri,x_forwarded_for_header_value,response
```

F5 - Multi-Severity Attack Incidents
```
index=netwaf 
| search attack_type="*SQL*" OR attack_type="*XSS*" OR attack_type="*CSRF*" OR attack_type="*SSRF*" OR attack_type="*IDOR*" OR attack_type="*Path Traversal*" OR attack_type="*Session Hijacking*" OR attack_type="*Remote File Include*" OR attack_type="*Code Injection*" OR attack_type="*Command Execution*" OR attack_type="*Buffer Overflow*" OR attack_type="*Information Leakage*"
| search severity="Critical" OR severity="High" OR severity="Medium"
| search x_forwarded_for_header_value!="N/A"
| table _time,attack_type,dest_port,method,policy_name,request_status,geo_location,severity,sig_cves,uri,x_forwarded_for_header_value,response
```

F5 - Web Logins
```
index=netwaf sourcetype="f5:bigip:asm:syslog" username!="N/A" 
| eval Time = strftime(_time,"%c") 
| table Time,host,username
```

F5 - Pool Status
```
index=netops  *Pool* status!="" 
| eval Time = strftime(_time,"%c") 
| table Time,pool,status
```
</details>

<details>
<summary><b>Symantec</b></summary>

Symantec Email - AntiMalware
```
index=symantec_email sourcetype="symantec:email:cloud:antimalware"
| table _time,malwareName,sender,orig_recipient
```
Symantec Email - AntiSpam
```
index=symantec_email sourcetype="symantec:email:cloud:antispam"
| table _time,sender,senderIp,recipient,subject,action,detectionMethod,emailSize
```

</details>

<details>
<summary><b>vCenter</b></summary>

vCenter - Logins
```
index=infraops source="vm*" "vim.event.UserLog*"
| table time,action,user,datastore,message
```
vCenter - VM Events
```
index=infraops source="vm*"  action="vim.event.VmBe*"
| table _time,action,user,message
```
</details>

<details>
<summary><b>FortiGate</b></summary>

FortiGate - Admin Login Failure Audit
```
index=netops result="Admin login failed"
| table date, time, host, src, srcip, status, src_user_name,reason
```
</details>

<details>
<summary><b>Cisco</b></summary>

Cisco Umbrella (DNS)
```
index=cisco_umbrella
| table _time,user,action,ReplyCode,RecordType,category,domain,granular_identity_type,identities,identity_type,s3_filename,src,src_translated_ip
```
Cisco Umbrella (Audit)
```
index=cisco_umbrella sourcetype="cisco:umbrella:audit" action!="" _raw!="*roamingdevices*"
| table _time,email,user,source_val,action,ip,body
```
Cisco ISE (Guest Users)
```
index=netauth SelectedAuthenticationIdentityStores="Guest Users" AuthenticationStatus="UnknownUser"
| table _time,"Framed_IP_Address",EndPointMatchedProfile,SelectedAuthorizationProfiles
```
Cisco Router logins
```
index=netops Login
| table _time,host,src,user,action
```
Cisco FMC - Blocked File Transfer Services
```
index=cisco_secure_fw file action=Block
| table _time,AC_RuleAction,Application,FirewallPolicy,FirewallRule,InitiatorIP,ResponderIP,URL,URL_Category
```
Cisco FMC - Audit Logs
```
index=osnix source="program:FMC.qudsbank.ps"  policy
| table _time,_raw
```
Cisco FMC Policy Changes
```
index=osnix source="program:FMC.qudsbank.ps"  "*policy deployment*" OR "*rule_configs*" OR "*Policy Committed*" OR "*Save Policy*"
| table _time,_raw
| sort -_time
```
Cisco SNA (Stealthwatch)
```
|securityevents domain_id=301 smc_ip=SNA_IP_ADDR earliest=-24h@h latest=now
            subject_ip= subject_host_group_id=
            peer_ip= peer_host_group_id= subject_orientation=EITHER
            security_event_type_id_list=all ports_list=
            hit_count_low_value= hit_count_high_value=
            ci_points_low_value= ci_points_high_value=
            filter_by=FLOW_COLLECTOR flow_collector_list="301" max_rows=2000 | sort 0 - ci_points | eval start_time=strftime(strptime(start_time."+0000","%Y-%m-%dT%H:%M:%SZ%z"),"%Y-%m-%d %H:%M:%S %Z") | eval last_time=strftime(strptime(last_time."+0000","%Y-%m-%dT%H:%M:%SZ%z"),"%Y-%m-%d %H:%M:%S %Z") | eval ci_points = tostring(ci_points, "commas"), hit_count = tostring(hit_count, "commas") | makemv delim=";" source_host_group_names | makemv delim=";" target_host_group_names | fields "fc_name", "start_time", "last_time", "event_type_name", "ci_points", "hit_count", "source_ip", "source_host_group_names", "source_hostname", "source_username", "source_mac", "target_ip", "target_host_group_names", "target_hostname", "target_username", "target_mac", "details" | rename "fc_name" as "Appliance", "start_time" as "Start Active Time", "last_time" as "Last Active Time", "event_type_name" as "Security Event", "source_ip" as "Source IP", "source_host_group_names" as "Source Host Group(s)", "source_hostname" as "Source Hostname", "target_ip" as "Target IP", "target_host_group_names" as "Target Host Group(s)", "target_hostname" as "Target Hostname", "ci_points" as "CI Points", "hit_count" as "Hit Count", "details" as "Details",  "source_username" as "Source Username",  "target_username" as "Target Username",  "source_mac" as "Source MAC",  "target_mac" as "Target MAC"
```
</details>

<details>
<summary><b>Senhasegura</b></summary>

Senhasegura - Sessions
```
index=pam OR index=osnix act=Session dhost!="null" suser!="asc_117"
| table _time,  sname ,suser ,src ,dhost ,dst ,duser ,proto
| rename sname as "Source Name", suser as "Source User", src as "Source IP", dhost as "Destitnation Host",dst as "Destination IP", proto as "Protocol", duser as "Destination User"
```
Senhasegura - Device Creation
```
index=pam OR index=osnix act=Device msg="Device creation*"
| table _time,sname,src,cs3,cs4
| rename cs3 as "Server Name" , src as "Source IP" ,sname as "User Name" , cs4 as "Log Details"
```
</details>

<details>
<summary><b>DBConnect</b></summary>

DBConnect - User Activity in DBConnect 
```
index=_audit sourcetype=audittrail action="db_connect*"
| eval Date=strftime(_time, "%Y/%d/%m")
| rex "user=(?<user>\S+),"
| stats count by Date, user, info, action
```
</details>

<details>
<summary><b>Others</b></summary>

Office365 - Attachment Size Policy
```
index=office365
| search "Parameters{}.Value"="Change_Me!"
| table _time,UserId,Parameters{}.Name,Parameters{}.Value
| rename UserId as "Modified by"
```
Idrac
```
index=idrac virtual console
| table _time,_raw
```
Detect Credit Card Numbers using Luhn Algorithm 
```
index=* ((source IN("*.log","*.bak","*.txt", "*.csv","/tmp*","/temp*","c:\tmp*")) OR (tag=web dest_content=*))
| eval comment="Match against the simple CC regex to narrow down the events in the lookup" 
| rex max_match=1 "[\"\s\'\,]{0,1}(?<CCMatch>[\d.\-\s]{11,24})[\"\s\'\,]{0,1}"
| where isnotnull(CCMatch) 
| eval comment="Apply the LUHN algorithm to see if the CC number extracted is valid" 
| eval cc=tonumber(replace(CCMatch,"[ -\.]",""))
| eval comment="Lower min to 11 to find additional CCs which may pick up POSIX timestamps as well."
| where len(cc)>=14 AND len(cc)<=16
| eval cc=printf("%024d", cc)
| eval ccd=split(cc,"") 
| foreach 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0 [
| eval ccd_reverse=mvappend(ccd_reverse,mvindex(ccd,<<FIELD>>))
]
| rename ccd_reverse AS ccd
| eval cce=mvappend(mvindex(ccd,0),mvindex(ccd,2),mvindex(ccd,4),mvindex(ccd,6),mvindex(ccd,8),mvindex(ccd,10),mvindex(ccd,12),mvindex(ccd,14),mvindex(ccd,16),mvindex(ccd,18),mvindex(ccd,20),mvindex(ccd,22),mvindex(ccd,24)) 
| eval cco=mvappend(mvindex(ccd,1),mvindex(ccd,3),mvindex(ccd,5),mvindex(ccd,7),mvindex(ccd,9),mvindex(ccd,11),mvindex(ccd,13),mvindex(ccd,15),mvindex(ccd,17),mvindex(ccd,19),mvindex(ccd,21),mvindex(ccd,23)) 
| eval cco2=mvmap(cco,cco*2) 
| eval cco2HT10=mvfilter(cco2>9) 
| eval cco2LT10=mvfilter(cco2<=9) 
| eval cco2LH10dt=mvmap(cco2HT10,cco2HT10-9) 
| fillnull value=0 cco2LT10 cco2LH10dt 
| eventstats sum(cce) as t1 sum(cco2LT10) as t2 sum(cco2LH10dt) as t3 BY cc 
| eval totalChecker=t1+t2+t3 
| eval CCIsValid=if((totalChecker%10)=0,"true","false")
| fields - cc ccd cce cco cco2 cco2HT10 cco2LT10 cco2LH10dt t1 t2 t3 totalChecker raw time
| where CCIsValid="true"
| eval comment="Find the field where we found the CC number" 
| foreach _raw * 
[
| eval CCStringField=if("<<FIELD>>"!="CCMatch" AND like('<<FIELD>>',"%".CCMatch."%"),"<<FIELD>>",CCStringField)
 ] 
| table _time CCMatch CCStringField source sourcetype host src dest http_user_agent
```
</details>

| Windows Event ID | Event Summary |
|---|---|
| 4720 | A user account was created |
| 4722 | A user account was enabled |
| 4723 | An attempt was made to change an account's password |
| 4724 | An attempt was made to reset an accounts password |
| 4725 | A user account was disabled |
| 4726 | A user account was deleted |
| 4738 | A user account was changed |
| 4781 | The name of an account was changed |
| 4782 | The password hash an account was accessed |
| 4624 | An account was successfully logged on |
| 4740 | A user account was locked out |
| 4634 | An account was logged off |
| 4625 | An account failed to log on |
| 4648 | A logon was attempted using explicit credentials |
| 4732 | A member was added to a security-enabled local group |
| 4728 | A member was added to a security-enabled global group |
| 4756 | A member was added to a security-enabled universal group |
| 4733 | A member was removed from a security-enabled local group |
| 4729 | A member was removed from a security-enabled global group |
| 4757 | A member was removed from a security-enabled universal group |
| 4657 | A registry value was modified |
| 4672 | Special privileges assigned to new logon |
| 4697 | A service was installed in the system |
| 4698 | A scheduled task was created |
| 4699 | A scheduled task was deleted |
| 4700 | A scheduled task was enabled |
| 4701 | A scheduled task was disabled |
| 4702 | A scheduled task was updated |
| 4608 | Windows is starting up |
| 4609 | Windows is shutting down |
| 4800 | The workstation was locked |
| 4801 | The workstation was unlocked |
| 5140 | A network share object was accessed |
| 5145 | A network share object was checked to see whether client can be granted desired access |
| 1102 | The audit log was cleared. (Security) |

Failure Information:

The section explains why the logon failed.

    Failure Reason: textual explanation of logon failure.
    Status and Sub Status: Hexadecimal codes explaining the logon failure reason. Sometimes Sub Status is filled in and sometimes not. Below are the codes we have observed.

| Status and Sub Status Codes | 	Description (not checked against "Failure Reason:")|
|---|---|
| 0xC0000064 | 	user name does not exist |
| 0xC000006A | 	user name is correct but the password is wrong |
| 0xC0000234 | 	user is currently locked out |
| 0xC0000072 | 	account is currently disabled |
| 0xC000006F | 	user tried to logon outside his day of week or time of day restrictions |
| 0xC0000070 | 	workstation restriction, or Authentication Policy Silo violation (look for event ID 4820 on domain controller) |
| 0xC0000193 | 	account expiration |
| 0xC0000071 | 	expired password |
| 0xC0000133 | 	clocks between DC and other computer too far out of sync |
| 0xC0000224 | 	user is required to change password at next logon |
| 0xC0000225 | 	evidently a bug in Windows and not a risk |
| 0xc000015b | 	The user has not been granted the requested logon type (aka logon right) at this machine |

Logon Types
| Type | Description |
|------|-------------|
| 2 | Console |
| 3 | Network |
| 4 | Batch (Scheduled Tasks) |
| 5 | Windows Services |
| 7 | Screen Lock/Unlock |
| 8 | Network (Cleartext Logon) |
| 9 | Alternate Credentials Specified (RunAs) |
| 10 | Remote Interactive (RDP) |
| 11 | Cached Credentials (e.g., Offline DC) |
| 12 | Cached Remote Interactive (RDP, similar to Type 10) |
| 13 | Cached Unlock (Similar to Type 7) |
