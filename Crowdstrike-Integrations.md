# Crowdstrike Integrations with Splunk Enterprise and ES

## Connections Required (Firewall Rules)
Allow access from Splunk Search Head server to the following APIs
- https://api.us-2.crowdstrike.com
- https://firehose.us-2.crowdstrike.com

## Event Streams Technical Add-on Installation
Detections, Events, Incidents and Audit info.
<br>
### Installation and Configuration
- From your Crowdstrike Portal generate the API key:

Support and resources -> API Clients & Keys (Add new API Client)
```
Name: Splunk_Events_TA
Scope: Event Streams
Permession: Read
```
- Download & Install [Event Streams Technical Add-on](https://splunkbase.splunk.com/app/5082)
- Splunk Architecture:
    - Search Head: The TA should be installed to provide field mapping and search macro support. 
    - Indexer: The TA can be installed to provide field mapping and search macro support
- Search Macros: settings, Advanced Search, Search macros
    - cs_es_get_index
    - cs_es_reset_action_logs
    - cs_es_ta_logs
    - cs_es_tc_input
- Predefined reports

## Intel Indecator Technical Add-on Installation
Retrieve Intelligence Indicator data from the CrowdStrike Intel Indicator API.
<br>
### Installation and Configuration
- From your Crowdstrike Portal generate the API key:

Support and resources -> API Clients & Keys (Add new API Client)
```
Name: Splunk_Intel_Indecators_TA
Scope: Indicators (Falcon Intelligence)
Permession: Read
```
- Download & Install [Intel Indecator Technical Add-on](https://splunkbase.splunk.com/app/5083)
- Splunk Architecture:
    - Search Head: The TA should be installed to provide field mapping and search macro support. 
    - Indexer: The TA can be installed to provide field mapping and search macro support
- Inputs Config: *Note it is not recommended to run the TA at intervals shorter than 5 minutes
- Search Macros: settings, Advanced Search, Search macros
    - cs_ii_get_index
- Predefined reports

## Device Technical Add-on Installation
Devices Information.
<br>
### Installation and Configuration
- From your Crowdstrike Portal generate the API key:

Support and resources -> API Clients & Keys (Add new API Client)
```
Name: Splunk_Device_Indecators_TA
Scope: Hosts
Permession: Read
```
- Download & Install [CrowdStrike Falcon Devices Technical Add-On](https://splunkbase.splunk.com/app/5570)
- Splunk Architecture:
    - Search Head: The TA should be installed to provide field mapping and search macro support. 
    - Indexer: The TA can be installed to provide field mapping and search macro support.
- Inputs config: CrowdStrike Device JSON
- Search Macros: settings, Advanced Search, Search macros
    - cs_fd_get_index
    - cs_fd_device_hostname(1) —> cs_fd_device_hostname(Win10-001)
    - cs_fd_get_device_id(1) —> cs_fd_get_device_id(c8b6q5716xa440408a29637ae244a0p1)
    - cs_fd_get_ip(1) —> cs_fd_get_ip(192.168.67.22)
- Predefined reports

## CrowdStrike Falcon Spotlight Vulnerability Data Add-on Installation
Vunlnerabilites Information.
<br>
### Installation and Configuration
- From your Crowdstrike Portal generate the API key:

Support and resources -> API Clients & Keys (Add new API Client)
```
Name: Splunk_spotlight_TA
Scope: Spotlight Vulnerabilities
Permession: Read
``` 
- Download & Install [[Event Streams Technical Add-on](https://splunkbase.splunk.com/app/6167)](https://splunkbase.splunk.com/app/6167)
- Splunk Architecture:
    - Search Head: The TA should be installed to provide field mapping and search macro support. 
    - Indexer: The TA can be installed to provide field mapping and search macro support.
- Inputs config: CrowdStrike Device JSON
- Search Macros: settings, Advanced Search, Search macros
    - cs_spotlight_get_index
    - CrowdStrike_Spotlight_AppName(1)
    - CrowdStrike_Spotlight_CVE(1)
- Predefined reports

## Crowdstrike Application for Splunk Installation
[CrowdStrike App](https://splunkbase.splunk.com/app/5094)

## SA-CrowdstrikeDevices for Enterprise Security
This supporting add-on comes with prebuilt content for CrowdStrike device data to be easily used with Splunk Enterprise Security's asset database.

[Download Link](https://splunkbase.splunk.com/app/6573)

[Documentation](https://splunk-sa-crowdstrike.ztsplunker.com)

## SA-CrowdStrikeIdentities for Enterprise Security
This supporting add-on comes with prebuilt content for CrowdStrike Identity data to be easily used with Splunk Enterprise Security's Identity database.

[Download Link](https://splunkbase.splunk.com/app/6930)

[Documentation](https://splunk-sa-crowdstrike-id.ztsplunker.com/)

## CrowdStrike Falcon Device Technical Add-On Guide v3.1.5
[Documentation](https://www.crowdstrike.com/wp-content/uploads/2022/12/CrowdStrike-Falcon-Device-Technical-Add-On-Guide-v3.1.5.pdf)
