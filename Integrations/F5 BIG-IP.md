## Security Logs
### Step 1

Security > Event Logs > Logging Profile > (Splunk - SC4S)

Logging Profile Prosperities:
- Application Security

Configuration
- Storage Destination: **Remote Storage**
- Logging Format: **Key-Value Pairs (Splunk)**
- Protocol: **UDP**
- IP Address: **<IP_ADDR>**
- Port: **514**

Advanced: **All Traffic**

Save

### Step 2
- Local Traffic -> Virtual Servers -> <VS> -> Security -> Policies -> Log Profile (**Splunk - SC4S**) -> Update


## Audit Logs
- System -> Logs -> Configuration -> Remote Logging
- System -> Logs -> Configuration -> Options

---

[Prepare F5 servers to connect to the Splunk platform](https://docs.splunk.com/Documentation/AddOns/released/F5BIGIP/Setup)
