[OpenCTI for Splunk Enterprise](https://splunkbase.splunk.com/app/8431)

[OpenCTI Add-on for Splunk](https://splunkbase.splunk.com/app/7485)

Append your **`CA certificate`** text to the end of that file:
```
cat /path/to/your/opencti_ca.pem >> /opt/splunk/etc/apps/TA-opencti-add-on/bin/ta_opencti_add_on/aob_py3/certifi/cacert.pem
```
Change hosts file
```
nano /etc/hosts

OPENCTI_IP_ADDR   opencti
```
Splunk
```
/opt/splunk/bin/splunk restart
/opt/splunk/bin/splunk show kvstore-status
chown -R splunk:splunk /root/.splunk/
```

