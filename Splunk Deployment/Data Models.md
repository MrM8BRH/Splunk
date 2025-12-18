The following search will give you a sourcetype breakdown of the events in datamodels
```
| datamodel
| rex field=_raw "\"modelName\"\s*\:\s*\"(?<modelName>[^\"]+)\""
| search NOT modelName IN (Splunk_CIM_Validation)
| fields modelName
| table modelName
| map maxsearches=40 search="tstats summariesonly=true count from datamodel=$modelName$ by sourcetype | eval modelName=\"$modelName$\""
| append [| search index=_internal source=*license_usage.log type="Usage" pool="herePutYourLicensePool"
  | eval sourcetype = st
  | stats count by sourcetype
  | eval modelName="removeit", count=0
  | fields sourcetype modelName count]
| xyseries sourcetype modelName count | fillnull value="N"
| fields - removeit
```
- [Optimizing data model acceleration for better performance](https://lantern.splunk.com/Platform_Data_Management/Optimize_Data/Optimizing_data_model_acceleration_for_better_performance)
- [How to Improve Your Data Model Acceleration in Splunk](https://hurricanelabs.com/splunk-tutorials/how-to-improve-your-data-model-acceleration-in-splunk/)
