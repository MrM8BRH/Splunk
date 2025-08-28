### How to get Windows data into your Splunk deployment
|                       Windows data you can collect                        |                Link to supporting documentation                |
|:-------------------------------------------------------------------------:|:--------------------------------------------------------------:|
| Event Logs                                                                | [Monitor Windows event log data with Splunk Enterprise](http://docs.splunk.com/Documentation/Splunk/9.4.2/Data/MonitorWindowseventlogdata)          |
| File system changes                                                       | [Monitor file system changes on Windows](http://docs.splunk.com/Documentation/Splunk/9.4.2/Data/MonitorfilesystemchangesonWindows)                         |
| Active Directory                                                          | [Monitor Active Directory](http://docs.splunk.com/Documentation/Splunk/9.4.2/Data/MonitorActiveDirectory)                                       |
| Data through the Windows Management Instrumentation (WMI) infrastructure  | [Monitor data through Windows Management Instrumentation (WMI)](http://docs.splunk.com/Documentation/Splunk/9.4.2/Data/MonitorWMIdata)  |
| Registry data                                                             | [Monitor Windows Registry data](http://docs.splunk.com/Documentation/Splunk/9.4.2/Data/MonitorWindowsregistrydata)                                  |
| Performance metrics                                                       | [Monitor Windows performance](http://docs.splunk.com/Documentation/Splunk/9.4.2/Data/MonitorWindowsperformance)                                    |
| Host information                                                          | [Monitor Windows host information](http://docs.splunk.com/Documentation/Splunk/9.4.2/Data/MonitorWindowshostinformation)                               |
| Print information                                                         | [Monitor Windows printer information](http://docs.splunk.com/Documentation/Splunk/9.4.2/Data/MonitorWindowsprinterinformation)                            |
| Network information                                                       | [Monitor Windows network information](http://docs.splunk.com/Documentation/Splunk/9.4.2/Data/MonitorWindowsnetworkinformation)                            |



### Powershell
[Monitor Windows data with PowerShell scripts](https://help.splunk.com/en/splunk-cloud-platform/get-started/get-data-in/9.3.2411/get-windows-data/monitor-windows-data-with-powershell-scripts)

[How to Use PowerShell Transcription Logs in Splunk](https://hurricanelabs.com/splunk-tutorials/how-to-use-powershell-transcription-logs-in-splunk/)

```
#Monitor PowerShell transcript logs
[monitor://C:\pstrans\*\*.txt]
sourcetype = powershell:transcript
index = powershell
disabled = 0
multiline_event_extra_waittime = true
time_before_close = 300

#Monitor PowerShell Windows Event Logs
[WinEventLog://Microsoft-Windows-PowerShell/Operational]
disabled = 0
renderXml = 1
index = powershell
source = XmlWinEventLog:Microsoft-Windows-PowerShell/Operational
sourcetype = XmlWinEventLog
```

```
[WinEventLog://Windows PowerShell]
disabled = 0
index=wineventlog
```

### Microsoft Defender XDR
[Splunk](https://learn.microsoft.com/en-us/defender-xdr/configure-siem-defender#splunk)

