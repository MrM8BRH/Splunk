<details>
<summary><b>Splunk Enterprise Security</b></summary>

Splunk Enterprise Security provides the security practitioner with visibility into security-relevant threats found in today's enterprise infrastructure. Splunk Enterprise Security is built on the Splunk operational intelligence platform and uses the search and correlation capabilities, allowing users to capture, monitor, and report on data from security devices, systems, and applications. As issues are identified, security analysts can quickly investigate and resolve the security threats across the access, endpoint, and network protection domains. 
- [About the ES solution architecture](https://dev.splunk.com/enterprise/docs/devtools/enterprisesecurity/abouttheessolution/)
</details>

<details>
<summary><b>Prerequisites</b></summary>

- [Minimum specifications for a production deployment](https://help.splunk.com/en/splunk-enterprise-security-8/install/8.3/planning/minimum-specifications-for-a-production-deployment)
- [Deployment considerations for Splunk Enterprise Security](https://help.splunk.com/en/splunk-enterprise-security-8/install/8.3/planning/deployment-considerations-for-splunk-enterprise-security)
- [Installing and upgrading to Splunk Enterprise Security 8x](https://lantern.splunk.com/Security/Product_Tips/Enterprise_Security/Installing_and_upgrading_to_Splunk_Enterprise_Security_8x)
Before initiating the installation process, it's important to verify if your data is CIM-compliant (normalization process) for all sources using multiple methods, including:
1. [The "SA-cim_vladiator" app](https://splunkbase.splunk.com/app/2968)
2. [Add-ons documentation](https://docs.splunk.com/Documentation/AddOns)
3. [Lantern (Data Descriptors)](https://lantern.splunk.com/Data_Descriptors)
4. [Splunk Connect for Syslog (Sources)](https://splunk.github.io/splunk-connect-for-syslog/releases/sources/)
</details>

<details>
<summary><b>Installation</b></summary>

Required Apps/Addons
- [Splunk Security Essentials](https://splunkbase.splunk.com/app/3435)
- [Splunk Enterprise Security](https://splunkbase.splunk.com/app/263)
- [Splunk ES Content Update](https://splunkbase.splunk.com/app/3449)
- [MITRE ATTACK App for Splunk](https://splunkbase.splunk.com/app/4617)

Optional
- [InfoSec App for Splunk](https://splunkbase.splunk.com/app/4240)
</details>

<details>
<summary><b>Configuration</b></summary>

- Configure → General settings
  - Distributed Configuration Management
  - Domain Analysis
  - Large Email Threshold
  - Configure Microsoft 365 index
  - Top 1 million site source

- Configure → All configurations → Data → CIM Setup

- Configure → All configurations → Data → Assets and identities
  - Asset Lookups → New → LDAP Lookup
  - Identity Lookups → New → LDAP Lookup
  - Correlation Setup → Enable for all sourcetypes

- Configure → Threat intelligence:
  - Threat intelligence sources
  - Proxy and parser settings → Parse domain from URL

- Security Content → Content Management
  - Type: Event-based detection
- Security Content → Security use case library

<details>
<summary><b>Search Macros</b></summary>
  - o365-index-value
  - aws-index-value
  - linux_auditd
  - linux_hosts
  - sysmon
  - admon
  - wineventlog_security
  - wineventlog_system
  - wineventlog_application
  - cisco_secure_firewall
  - linux_auditd_normalized_execve_process
  - linux_auditd_normalized_proctitle_process
  - normalized_service_binary_field
  - cisco_networks
  - o365_suspect_search_terms_regex
  - system_network_configuration_discovery_tools
  - appLocker
  - capi2_operational
  - certificateservices_lifecycle
  - powershell
  - printservice
  - remoteconnectionmanager
  - o365_suspect_search_terms_regex
  - crowdstrike_identities
  - crowdstrike_stream
</details>
</details>

<details>
<summary><b>SPL Queries</b></summary>

```
`notable` | search NOT `suppression` 
```
```
| inputlookup append=t es_notable_events
```
```
index=notable
 
| append [
  | rest /servicesNS/-/-/saved/searches splunk_server=local
  | search action.correlationsearch.enabled=1 disabled=0
  | fields title
  | rename title AS search_name
  | eval _time=946688461 ]

| eval search_name=replace(search_name, "\S+ - (.+) - \S+$", "\1")

| stats sparkline, count, max(_time) AS last_seen, min(_time) AS first_seen by search_name

| eval _comment="Only active ones will meet following criteria"
| where first_seen=946688461

| eval days_missing=round((now()-last_seen)/84600)
| eval last_seen=strftime(last_seen, "%F")
| sort 0 +num(last_seen), -num(days_missing)

| eval count=if(last_seen="2000-01-01", 0, count)
| eval days_missing=case(last_seen="2000-01-01", "Never seen!", days_missing=0, "Today :)", 1=1, days_missing)
| eval last_seen=if(last_seen="2000-01-01", "Never seen!", last_seen)

| streamstats count AS ID

| table ID search_name sparkline days_missing last_seen
```

<details>
<summary><b>List all ES Correlation Searches</b></summary>
  
```
| rest splunk_server=local count=0 /services/saved/searches 
| where match('action.correlationsearch.enabled', "1|[Tt]|[Tt][Rr][Uu][Ee]") 
| rex field=action.customsearchbuilder.spec "datamodel\\\":\s+\\\"(?<Data_Model>\w+)" 
| rex field=action.customsearchbuilder.spec "object\\\":\s+\\\"(?<Dataset>\w+)" 
| rename
    action.correlationsearch.label as Search_Name
    title as Rule_Name
    eai:acl.app as Application_Context
    description as Description
    Data_Model as Guided_Mode:Data_Model
    Dataset as Guided_Mode:Dataset
    action.customsearchbuilder.enabled as Guided_Mode
    search as Search
    dispatch.earliest_time as Earliest_Time
    dispatch.latest_time as Latest_Time
    cron_schedule as Cron_Schedule
    schedule_window as Schedule_Window
    schedule_priority as Schedule_Priority
    alert_type as Trigger_Conditions:Trigger_Alert_When
    alert_comparator as Trigger_Conditions:Alert_Comparator
    alert_threshold as Trigger_Conditions:Alert_Threshold
    alert.suppress.period as Throttling:Window_Duration
    alert.suppress.fields as Throttling:Fields_To_Group_By
    action.notable.param.rule_title as Notable:Title
    action.notable.param.rule_description as Notable:Description
    action.notable.param.security_domain as Notable:Security_Domain
    action.notable.param.severity as Notable:Severity
| eval Guided_Mode:Enabled = if(Guided_Mode == 1, "Yes", "No") 
| eval Real-time_Scheduling_Enabled = if(realtime_schedule == 1, "Yes", "No") 
| table
    disabled 
    Search_Name,
    Rule_Name,
    Application_Context,
    Description,
    Guided_Mode:Enabled,
    Guided_Mode:Data_Model,
    Guided_Mode:Dataset,
    Search,
    Earliest_Time,
    Latest_Time,
    Cron_Schedule,
    Real-time_Scheduling_Enabled,
    Schedule_Window,
    Schedule_Priority,
    Trigger_Conditions:Trigger_Alert_When,
    Trigger_Conditions:Alert_Comparator,
    Trigger_Conditions:Alert_Threshold,
    Throttling:Window_Duration,
    Throttling:Fields_To_Group_By,
    Notable:Title,
    Notable:Description,
    Notable:Security_Domain,
    Notable:Severity,
```
</details>
</details>

<details>
<summary><b>Install/Update Splunk ES (Linux)</b></summary>
  
```
mv /root/splunk-enterprise-security_<version>.spl /opt/splunk/
chown splunk:splunk /opt/splunk/splunk-enterprise-security_<version>.spl
chmod 644 /opt/splunk/splunk-enterprise-security_<version>.spl
cd /opt/splunk
/opt/splunk/bin/splunk install app splunk-enterprise-security_<version>.spl -update 1
```
</details>

<details>
<summary><b>Uninstall Splunk ES (Linux)</b></summary>

```
# Stop Splunk
/opt/splunk/bin/splunk stop

# Uninstall Splunk ES
cd /opt/splunk/etc/apps
rm -r SplunkEnterpriseSecuritySuite missioncontrol SA-* DA-ESS*
```
</details>

<details>
<summary><b>Resrouces</b></summary>

Enterprise Security
- [Administer Splunk Enterprise Security](https://help.splunk.com/en/splunk-enterprise-security-7/administer/7.3/overview/administering-splunk-enterprise-security)
- [Manage internal lookups in Splunk Enterprise Security](https://help.splunk.com/en/splunk-enterprise-security-7/administer/7.3/managing-content/manage-internal-lookups-in-splunk-enterprise-security)
- [Manage assets and identities in Splunk Enterprise Security](https://help.splunk.com/en/splunk-enterprise-security-7/administer/7.3/asset-and-identity-management/manage-assets-and-identities-in-splunk-enterprise-security)
- [Manage UI issues impacting threat intelligence after upgrading Splunk Enterprise Security](https://help.splunk.com/en/splunk-enterprise-security-7/administer/7.3/threat-intelligence/manage-ui-issues-impacting-threat-intelligence-after-upgrading-splunk-enterprise-security)
- [Add intelligence to Splunk Enterprise Security](https://help.splunk.com/en/splunk-enterprise-security-7/administer/7.3/generic-intelligence/add-intelligence-to-splunk-enterprise-security)

Lantern
- [Optimizing Splunk Enterprise Security for your SOC](https://lantern.splunk.com/Security_Use_Cases/Automation_and_Orchestration/Optimizing_Splunk_Enterprise_Security_for_your_SOC)
- [Getting Started With Splunk Enterprise Security](https://lantern.splunk.com/Security/Getting_Started)
- [Using threat intelligence in Splunk Enterprise Security](https://lantern.splunk.com/Security/UCE/Prioritized_Actions/Threat_intelligence/Using_threat_intelligence_in_Splunk_Enterprise_Security)
- [Configuring and optimizing Enterprise Security](https://lantern.splunk.com/Security/Getting_Started/Configuring_and_optimizing_Enterprise_Security)
- [Using Enterprise Security for security investigation and monitoring](https://lantern.splunk.com/Security/Getting_Started/Using_Enterprise_Security_for_security_investigation_and_monitoring)
- [Foundational Visibility](https://lantern.splunk.com/Security/UCE/Foundational_Visibility)
- [Cyber frameworks](https://lantern.splunk.com/Security/UCE/Prioritized_Actions/Cyber_frameworks)
- [Proactive Response](https://lantern.splunk.com/Security/UCE/Proactive_Response)
- [Optimized Experiences](https://lantern.splunk.com/Security/UCE/Optimized_Experiences)

Normalization
- [How to use the CIM data model reference tables](https://docs.splunk.com/Documentation/CIM/latest/User/Howtousethesereferencetables)
- [Use the CIM to normalize data at search time](https://docs.splunk.com/Documentation/CIM/latest/User/UsetheCIMtonormalizedataatsearchtime)
- [Normalizing values to a common field name with the Common Information Model (CIM)](https://lantern.splunk.com/Splunk_Platform/Product_Tips/Data_Management/Normalizing_values_to_a_common_field_name_with_the_Common_Information_Model_(CIM))

</details>
