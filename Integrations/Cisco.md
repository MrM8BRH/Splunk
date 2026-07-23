- [Cisco Security Cloud](https://splunkbase.splunk.com/app/7404)
- [Cisco Security Cloud App for Splunk User Guide](https://www.cisco.com/c/en/us/td/docs/security/cisco-secure-cloud-app/user-guide/cisco-security-cloud-user-guide/m_cisco_security_cloud_overview.html)
- [Cisco Secure Firewall Management Center](https://www.cisco.com/c/en/us/td/docs/security/cisco-secure-cloud-app/user-guide/cisco-security-cloud-user-guide/m_configure_cisco_products_in_cisco_security_cloud.html#secure-firewall)

---

[Cisco Security Cloud Estreamer Issues](https://community.splunk.com/t5/Getting-Data-In/Cisco-Security-Cloud-Estreamer-Issues/m-p/758434)

Filter
props.conf
```
[cisco:estreamer:data]
TRANSFORMS-routing = drop_denied_connections
```
transforms.conf
```
[drop_denied_connections]
REGEX = AccessControlRuleAction:\s*Block
DEST_KEY = queue
FORMAT = nullQueue
```
