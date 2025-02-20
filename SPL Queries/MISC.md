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

SSH Logins
```
index=linux "Accepted Publickey" OR "session opened" OR "Accepted password" src!="PAM_IP_ADDR" src!="" user!=""  | table _time,user,src,dest,src_port,sshd_protocol,action
```

SSH Logins (Syslog - SC4S)
```
index=osnix source="program:sshd" "Accepted Publickey" OR "session opened" _raw!="*PAM_IP_ADDR*" 
| table _time,host,sc4s_fromhostip,user 
| dedup _time,host,user | sort -_time
```

Console logins for Linux Servers
```
index=osnix OR index=linux "Started Session 7 of" 
| table _time,host,_raw
```

</details>


<details>
<summary><b>Appian</b></summary>

Admin Console
```
index=appian source="*admin_console.csv" | table _time,Property,Count
```
Blocked Files
```
index=appian source="*blocked_files.csv*" | table _time,User,"Document Name",Reason,Details,Hash
```
Data Store Deletions
```
index=appian source="*data_store_deletions*" | table _time,"Data Store",Entity,Id,"Node Display Name",User
```
Decryption
```
index=appian source="*decryption.csv*" | table _time,Username,Context,Action,Success
```
DevOps Infrastructure
```
index=appian source="*devops_infrastructure.csv" | table _time,ID,Name,URL,"Last Action Username","Last Action Type","Last Action Name","Last Action IP","Last Action Date","Remote Enabled"
```
Devops Infrastructure Handler
```
index=appian source="*devops_infrastructure_handler.csv" | table ID,Name,URL,"IP Address","Status Code","Error Occurred","Direction","Before or After Request Processed"
```
File Attachment Downloads
```
index=appian source="*file_attachment_downloads.csv*" "File name"!="*.png" "File name"!="*.ico" "File name"!="*.jpg" | table _time,User,"File name","Download Successful"
```
Login Audit
```
index=appian source="*login-audit.csv" API_USER!="API-USER" | table _time,API_USER,"Web API",Succeeded | rename API_USER as "User" , Succeeded as "Action"
```
Object Rolemap Audit
```
index=appian source="*object_rolemap_audit.csv" | table _time,Username,Name,Type,"Previous Rolemap","New Rolemap"
```
Records Usage
```
index=appian source="*records_usage.csv*" | table _time,User,View,"Record Type Name",Action
```
Removed Processes
```
index=appian source="*removed*" | table _time,Action,"Process ID","Process Name","Transaction ID",Username
```
Sites Usage
```
index=appian source="*sites_usage.csv*" | table _time,User,Site,Page,Action
```
Users
```
index=appian source="*users.csv" | table _time,"Active LDAP Users","Active SAML Users","Active System Administrators","Active Tempo Users","Active Users","Total Users"
```
User Management
```
index=appian source="*user_management.csv" | search Action!="Log Initialized" | table _time,Action,"Modified By Username",Username,"Original Value","New Value"
```

</details>

<details>
<summary><b>CrowdStrike</b></summary>

Logins
```
index=crowdstrike user!="" action!="" | table _time,user,event.ServiceName,action
```
CrowdStrike FW - RDP Sessions
```
index=crowdstrike rdp event.LocalAddress!="PAM_IP_ADDR" 
| table _time,event.HostName,event.LocalAddress,event.RemoteAddress,event.PolicyName,event.RuleGroupName,event.RuleAction
```
Malware Detections
```
index="crowdstrike" "metadata.eventType"=DetectionSummaryEvent metadata.customerIDString=* event.DetectId!="" 
| table _time,action,description,event.ComputerName,event.DetectName,event.FileName,event.FilePath,event.IOCType,event.IOCValue,event.LocalIP,event.MACAddress,event.Objective,event.SeverityName,event.Tactic,event.Technique,event.UserName,event.CommandLine,event.AssociatedFile
```
Policies
```
index=crowdstrike "metadata.eventType"=UserActivityAuditEvent
| search "event.OperationName"=*policy 
| table _time,*OperationName,*ServiceName,*UserId,*UserIp,*policy_name,*policy_enabled
```
FileVantage
```
index="crowdstrike" source=crowdstrike_filevantage_json
| table _time,entity_type,severity,action_type,action_timestamp,command_line,entity_path,grandparent_process_image_file_name,parent_process_image_file_name,host.name,host.local_ip,host.os_version,policy.name,policy.rule_group.name
```
Identities
```
index=crowdstrike sourcetype="crowdstrike:identities" riskScoreSeverity="HIGH" 
| table _time,primaryDisplayName,isHuman,isProgrammatic,emailAddresses{},accounts{}.userAccountControl,accounts{}.title,accounts{}.samAccountName,accounts{}.ou,accounts{}.enabled,accounts{}.dn,accounts{}.dataSource,accounts{}.department,accounts{}.description,type,roles{}.type,riskScoreSeverity,riskFactors{}.type,riskFactors{}.severity
```
Event Streams
```
index=crowdstrike sourcetype="CrowdStrike:Event:Streams:JSON" 
| table _time,ta_*,metadata.eventType,event.UserIp,event.Source,event.SourceIp,event.OperationName,event.Attributes.scopes,event.Attributes.produces,action
```
</details>

<details>
<summary><b>F5</b></summary>

Alert
```
index=netwaf severity="Critical" OR severity="High" AND  request_status="blocked" 
| table _time,attack_type,severity,sig_cves,sub_violations,"blocking_exception_reason",captcha_result,device_id,f5_bigip_service,geo_location,http_class_name,ip_client,method,request_status,response,request,uri,x_forwarded_for_header_value, violations
```
Audit
```
index=netops host="*waf*" sourcetype="f5:bigip:syslog" AUDIT object  | table _time,_raw
```
Report
```
index=netwaf severity="Critical" OR severity="High" OR severity="Medium" AND  request_status="blocked" 
| table _time,attack_type,severity,sig_cves,sub_violations,"blocking_exception_reason",captcha_result,device_id,f5_bigip_service,geo_location,http_class_name,ip_client,method,request_status,response,request,uri,x_forwarded_for_header_value, violations
```

</details>

<details>
<summary><b>Symantec</b></summary>

Email - AntiMalware
```
index=symantec_email sourcetype="symantec:email:cloud:antimalware" | table _time,malwareName,sender,orig_recipient
```
Email - AntiSpam
```
index=symantec_email sourcetype="symantec:email:cloud:antispam" | table _time,sender,senderIp,recipient,subject,action,detectionMethod,emailSize
```

</details>

<details>
<summary><b>vCenter</b></summary>

Logins
```
index=infraops source="vm*" "vim.event.UserLog*" | table time,action,user,datastore,message
```
VM Events
```
index=infraops source="vm*"  action="vim.event.VmBe*" | table _time,action,user,message
```
</details>

<details>
<summary><b>Cisco</b></summary>

Umbrella (DNS)
```
index=cisco_umbrella | table _time,user,action,ReplyCode,RecordType,category,domain,granular_identity_type,identities,identity_type,s3_filename,src,src_translated_ip
```
Umbrella (Audit)
```
index=cisco_umbrella sourcetype="cisco:umbrella:audit" action!="" _raw!="*roamingdevices*" | table _time,email,user,source_val,action,ip,body
```
ISE (Guest Users)
```
index=netauth SelectedAuthenticationIdentityStores="Guest Users" AuthenticationStatus="UnknownUser" | table _time,"Framed_IP_Address",EndPointMatchedProfile,SelectedAuthorizationProfiles
```
Router logins
```
index=netops Login | table _time,host,src,user,action
```
FMC - Blocked File Transfer Services
```
index=cisco_secure_fw file action=Block | table _time,AC_RuleAction,Application,FirewallPolicy,FirewallRule,InitiatorIP,ResponderIP,URL,URL_Category
```
FMC - Audit Logs
```
index=osnix source="program:FMC.qudsbank.ps"  policy | table _time,_raw
```
FMC Policy Changes
```
index=osnix source="program:FMC.qudsbank.ps"  "*policy deployment*" OR "*rule_configs*" OR "*Policy Committed*" OR "*Save Policy*" | table _time,_raw | sort -_time
```
SNA (Stealthwatch)
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

Sessions
```
index=pam act=Session dhost!="null" suser!="asc_117" | table _time,  sname ,suser ,src ,dhost ,dst ,duser ,proto  | rename sname as "Source Name", suser as "Source User", src as "Source IP", dhost as "Destitnation Host",dst as "Destination IP", proto as "Protocol", duser as "Destination User"
```
Device Creation
```
index=pam act=Device msg="Device creation*" | table _time,sname,src,cs3,cs4 | rename cs3 as "Server Name" , src as "Source IP" ,sname as "User Name" , cs4 as "Log Details"
```
</details>

<details>
<summary><b>Others</b></summary>

Office365 - Attachment Size Policy
```
index=office365 | search "Parameters{}.Value"="Change_Me!" | table _time,UserId,Parameters{}.Name,Parameters{}.Value | rename UserId as "Modified by"
```
Idrac
```
index=idrac virtual console | table _time,_raw
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
