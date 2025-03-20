## Splunk Common Network Ports
This is a diagram of Splunk components and network ports that are commonly used in a Splunk Enterprise environment. Firewall rules often need to be updated to allow communication on ports 8000, 8089, 9997, 8080 and 514.

![Ports](https://github.com/MrM8BRH/Splunk/assets/34133187/73a05f58-7be5-4b71-ada3-46487459bbc1)

Open required ports (adjust based on your deployment):
```bash
sudo firewall-cmd --permanent --add-port=8000/tcp  # Splunk Web
sudo firewall-cmd --permanent --add-port=8089/tcp  # Management port
sudo firewall-cmd --permanent --add-port=9997/tcp  # Forwarder data ingestion
sudo firewall-cmd --reload
```
Verify open ports:
```bash
sudo firewall-cmd --list-ports
```
## CrowdStrike
```
https://api.us-2.crowdstrike.com
https://firehose.us-2.crowdstrike.com
```
## Splunk
```
https://www.splunk.com/
https://login.splunk.com/
https://download.splunk.com
https://splunkbase.splunk.com/
```
