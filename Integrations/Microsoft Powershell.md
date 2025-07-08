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
