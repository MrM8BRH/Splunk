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

Local Traffic -> Virtual Servers -> <VS> -> Security -> Policies -> Log Profile (**Splunk - SC4S**) -> Update

---

- [Task 1: Install the F5 Splunk app in Splunk¶](https://clouddocs.f5.com/training/community/analytics/html/class2/modules/task1.html)
- [Task 2: Import and configure the F5 Analytics iApp template on the BIG-IP¶](https://clouddocs.f5.com/training/community/analytics/html/class2/modules/task2.html)
- [Task 3: Visualize the analytics data in Splunk¶](https://clouddocs.f5.com/training/community/analytics/html/class2/modules/module4.html#task-3-visualize-the-analytics-data-in-splunk)
