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
<summary><b>Active Directory</b></summary>

 Dormant Account
```
| ldapsearch domain=default search="(&(objectclass=user)(!(objectClass=computer)))" limit=0 attrs="sAMAccountName, displayName, distinguishedName, userAccountControl, whenCreated, accountExpires, lastLogonTimestamp"
| makemv userAccountControl
| search dn!="*OU=_Disabled Users*" userAccountControl!="*ACCOUNTDISABLE*"
| eval accountDisable=if(userAccountControl == "ACCOUNTDISABLE
 NORMAL_ACCOUNT", "Yes", "No")
| eval dontExpirePasswd=if(userAccountControl="DONT_EXPIRE_PASSWD
 NORMAL_ACCOUNT", "Yes", "No")
| eval passwdNotRequired=if(userAccountControl == "PASSWD_NOTREQD
 NORMAL_ACCOUNT", "Yes", "No")
| eval lastLoginAge_epoch=strptime(lastLogonTimestamp, "%Y-%m-%dT%H:%M:%S")
| eval lastLoginAge=round((lastLoginAge_epoch - now())/86400, 0)
| where lastLoginAge < -90
| table sAMAccountName, displayName, dn, userAccountControl, whenCreated, accountDisable, dontExpirePasswd, passwdNotRequired, lastLoginAge, lastLogonTimestamp, accountExpires
```

Passwords Never Changed - Active Accounts:
```
| ldapsearch domain=default search="(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2))(userAccountControl:1.2.840.113556.1.4.803:=65536))" attrs="sAMAccountName,pwdLastSet" | table sAMAccountName, dn, pwdLastSet
```

Passwords Last Changed - Active Accounts:
```
| ldapsearch domain="default" search="(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" attrs="sAMAccountName,pwdLastSet" | table sAMAccountName, pwdLastSet
```

Check for Disabled User Accounts:
```
| ldapsearch domain="default" search="(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=2))" attrs="sAMAccountName" | table sAMAccountName,dn
```

RDP Connections
```
index=wineventlog EventCode=1149 | table _time,Account_Domain,Account_Name,action,app,command,user,src,src_user,dest
```

Member Added/Removed
```
index="wineventlog" EventCode=4761 OR EventCode=4762 OR EventCode=4728 OR EventCode=4729 |eval time = strftime(_time,"%c") |table time,name,MemberName,Group_Name,src_user |rename time as "Time" , name as "Action" , MemberName as "Member Name Added/Removed" , Group_Name as "Group Name" , src_user as "Member Added/Removed By :"
```

Security Group mgmt changed:
```
index="wineventlog" EventCode=4735 OR EventCode=4737 |eval time = strftime(_time,"%c") |table time,name,src_user,TargetUserName,dest,session_id |rename time as "Time" , name as "Action" , src_user as "Source User", TargetUserName as " Target Group " , dest as " Destination DC" , session_id as "Session ID"
```

User Enabled/Disabled:
```
index="wineventlog" EventCode=4722 OR EventCode=4725 |eval time = strftime(_time,"%c") |table time,name,user,src_user |rename time as "Time" , name as "Action" , user as "Target User" , src_user as "Account Enabled/Disabled By"
```

UserAccount Locked/Unlocked:
```
index="wineventlog" signature="A user account was locked out" OR signature="A user account was unlocked" |eval time = strftime(_time,"%c") |table time,dest_nt_domain,Group_Name,name,src_user |rename time as "Time" , Group_Name as "User Name" , dest_nt_domain as "Hostname", name as "Action" , src_user as "Locked/Unlocked By"
```

UserAccount Changed:
```
index="wineventlog" signature="A user account was changed" |eval time = strftime(_time,"%c") |table time,name,user,src_user,dest |rename time as "Time" , name as "Action" , user as " Target User" , src_user as "Changed By" , dest as "Destination DC"
```

User Created:
```
index="wineventlog" EventCode=4720 |eval time = strftime(_time,"%c") |table time,name,user,Logon_ID,src_user,dest |rename time as "Time" , name as "Action" , user as "Created User" , Logon_ID as "Session ID" ,src_user as "User Created By :", dest as "Destination DC"
```

Domain Policy Changed/Reset Passowrd:
```
index="wineventlog" signature="An attempt was made to change an account's password" OR signature="An attempt was made to reset an accounts password" |eval time = strftime(_time,"%c") |table time,name,user,src_user |rename time as "Time" , name as "Action" , user as "Target User" , src_user as "Password Changed/Reset By"
```

User Deleted By Admin:
```
index="wineventlog" EventCode=4726 |eval time = strftime(_time,"%c") |table time,name,src_user,user,dest |rename time as "Time" , name as "Action" , src_user as "Deleted By : ", user as "Deleted User: " , dest as "Destination DC"
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
| Logon Type |	#	| Authenticators Accepted |	Reusable Credentials in LSA Session	| Examples |
|------------|---|-------------------------|-------------------------------------|----------|
| Interactive (also known as, Logon locally) | 2 |	Password, Smartcard,other |	Yes | 	Console logon;RUNAS;Hardware remote control solutions (such as Network KVM or Remote Access / Lights-Out Card in server)IIS Basic Auth (before IIS 6.0) |
| Network 	| 3 |	Password,NT Hash,Kerberos ticket |	No (except if delegation is enabled, then Kerberos tickets present) |	NET USE;RPC calls;Remote registry;IIS integrated Windows auth;SQL Windows auth; |
| Batch |	4 |	Password (stored as LSA secret) |	Yes |	Scheduled tasks |
| Service |	5 |	Password (stored as LSA secret) |	Yes |	Windows services |
| NetworkCleartext |	8 |	Password |	Yes |	IIS Basic Auth (IIS 6.0 and newer);Windows PowerShell with CredSSP |
| NewCredentials |	9 |	Password |	Yes |	RUNAS /NETWORK |
| RemoteInteractive |	10 |	Password, Smartcard,other |	Yes |	Remote Desktop (formerly known as "Terminal Services") |
