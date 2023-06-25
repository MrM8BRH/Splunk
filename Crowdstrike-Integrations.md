# Crowdstrike Integrations with Splunk Enterprise and ES
<br>

## Connections Required (Firewall Rules)
Allow access from Splunk Search Head server to the following APIs
- https://api.us-2.crowdstrike.com
- https://firehose.us-2.crowdstrike.com

<br>

## Event Streams Technical Add-on Installation
Detections, Events, Incidents and Audit info.
<br>
### Installation and Configuration
- From your crowdstrike protal generate the API key: Support, API Clients & Keys, Add new API Client, Splunk_Events_TA, Event Streams
- Download & Install [Event Streams Technical Add-on](https://splunkbase.splunk.com/app/5082)
- Splunk Architicture:
    - Search Head: The TA should be installed to provide field mapping and search macro support. 
    - Indexer: The TA can be installed to provide field mapping and search macro support
- Search Macros: settings, Advanced Search, Search macros
    - cs_es_get_index
    - cs_es_reset_action_logs
    - cs_es_ta_logs
    - cs_es_tc_input
- Predefined reports

<br>

## Intel Indecator Technical Add-on Installation
Retrieve Intelligence Indicator data from the CrowdStrike Intel Indicator API.
<br>
### Installation and Configuration
- From your crowdstrike protal generate the API key: Support, API Clients & Keys, Add new API Client, Splunk_Intel_Indecators_TA, Indicators (Falcon Intelligence)
- Download & Install [Event Streams Technical Add-on](https://splunkbase.splunk.com/app/5083)
- Splunk Architicture:
    - Search Head: The TA should be installed to provide field mapping and search macro support. 
    - Indexer: The TA can be installed to provide field mapping and search macro support
- Inputs Config: *Note it is not recommended to run the TA at intervals shorter than 5 minutes
- Search Macros: settings, Advanced Search, Search macros
    - cs_ii_get_index
- Predefined reports

<br>

## Device Technical Add-on Installation
Devices Information.
<br>
### Installation and Configuration
- From your crowdstrike protal generate the API key: Support, API Clients & Keys, Add new API Client, Splunk_Device_Indecators_TA, Hosts
- Download & Install [Event Streams Technical Add-on](https://splunkbase.splunk.com/app/5570)
- Splunk Architicture:
    - Search Head: The TA should be installed to provide field mapping and search macro support. 
    - Indexer: The TA can be installed to provide field mapping and search macro support.
- Inputs config: CrowdStrike Device JSON
- Search Macros: settings, Advanced Search, Search macros
    - cs_fd_get_index
    - cs_fd_device_hostname(1) —> cs_fd_device_hostname(Win10-001)
    - cs_fd_get_device_id(1) —> cs_fd_get_device_id(c8b6q5716xa440408a29637ae244a0p1)
    - cs_fd_get_ip(1) —> cs_fd_get_ip(192.168.67.22)
- Predefined reports


<br>

## CrowdStrike Falcon Spotlight Vulnerability Data Add-on Installation
Vunlnerabilites Information.
<br>
### Installation and Configuration
- From your crowdstrike protal generate the API key: Support, API Clients & Keys, Add new API Client, Splunk_spotlight_TA, Spotlight Vulnerabilities 
- Download & Install [Event Streams Technical Add-on](https://splunkbase.splunk.com/app/6167)
- Splunk Architicture:
    - Search Head: The TA should be installed to provide field mapping and search macro support. 
    - Indexer: The TA can be installed to provide field mapping and search macro support.
- Inputs config: CrowdStrike Device JSON
- Search Macros: settings, Advanced Search, Search macros
    - cs_spotlight_get_index
    - CrowdStrike_Spotlight_AppName(1)
    - CrowdStrike_Spotlight_CVE(1)
- Predefined reports

## Crowdstrike Application for Splunk Installation
https://splunkbase.splunk.com/app/5094

<br>

## CrowdStrike Falcon Devices Technical Add-On
This supporting add-on comes with prebuilt content for CrowdStrike device data to be easily used with Splunk Enterprise Security's asset database.

[Download Link](https://splunkbase.splunk.com/app/6573)

[Documentation](https://splunk-sa-crowdstrike.ztsplunker.com)

<br>

## SA-CrowdStrikeIdentities for Enterprise Security
This supporting add-on comes with prebuilt content for CrowdStrike Identity data to be easily used with Splunk Enterprise Security's Identity database.

[Download Link](https://splunkbase.splunk.com/app/6930)

[Documentation](https://splunk-sa-crowdstrike-id.ztsplunker.com/)
   
