[How to Setup Rsyslog Client to Send Logs to Rsyslog Server in CentOS 7](https://www.tecmint.com/setup-rsyslog-client-to-send-logs-to-rsyslog-server-in-centos-7/)

<details>

<summary><b>Syslog-ng (Old)</b></summary>

### Installation
#### CentOS
```
dnf install -y epel-release
dnf install -y syslog-ng
systemctl enable syslog-ng
systemctl start syslog-ng
```

#### Debian
```
apt install syslog-ng
```

If you face dependencies issues:
```
wget -qO - https://ose-repo.syslog-ng.com/apt/syslog-ng-ose-pub.asc | sudo apt-key add -
echo "deb https://ose-repo.syslog-ng.com/apt/ nightly ubuntu-jammy" | sudo tee -a /etc/apt/sources.list.d/syslog-ng-ose.list
apt update
apt install syslog-ng
```
#### Script
`nano script.sh`
```
#!/bin/bash
# backup .conf files:
cp -f /etc/sysctl.conf{,.bak}
# adding parameters
sh -c 'echo "fs.file-max = 65535" >> /etc/sysctl.conf'
sh -c 'echo "net.core.somaxconn = 65535" >> /etc/sysctl.conf'
sh -c 'echo "net.core.rmem_default = 33554432" >> /etc/sysctl.conf'
sh -c 'echo "net.core.rmem_max = 33554432" >> /etc/sysctl.conf'
sh -c 'echo "net.core.netdev_max_backlog = 10000" >> /etc/sysctl.conf'
```
`chmod +x script.sh`

`./script.sh`

### Configuration
#### CentOS
```
cp /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.backup
nano /etc/syslog-ng/syslog-ng.conf
```
#### Debian
```
cp /etc/syslog-ng.conf /etc/syslog-ng.conf.bkp
nano /etc/syslog-ng.conf
```

### Config File
<details>
 
 <summary>Conf File</summary>
 
```
@version:3.5
@include "scl.conf"
# syslog-ng configuration file.
#
# This should behave pretty much like the original syslog on RedHat. But
# it could be configured a lot smarter.
#
# See syslog-ng(8) and syslog-ng.conf(5) for more information.
#
# Note: it also sources additional configuration files (*.conf)
#       located in /etc/syslog-ng/conf.d/
options {
flush_lines (0);
time_reopen (1);
create_dirs(yes);
log_fifo_size (4096);
log_msg_size(8192);
chain_hostnames (no);
use_dns (no);
use_fqdn (no);
keep_hostname (yes);
perm(0644);
dir_perm(0755);
};
source s_syn {
udp(ip(0.0.0.0) port(5514));
};
source s_syf {
udp(ip(0.0.0.0) port(6514));
};
source s_syd {
udp(ip(0.0.0.0) port(514));
};

destination d_n { file("/var/log/syslog-ng/networks/$HOST/$YEAR$MONTH$DAY.log"); };
destination d_f { file("/var/log/syslog-ng/security/$HOST/$YEAR$MONTH$DAY.log"); };
destination d_d { file("/var/log/syslog-ng/default/$HOST/$YEAR$MONTH$DAY.log"); };

log { source(s_syn); destination(d_n); };
log { source(s_syf); destination(d_f); };
log { source(s_syd); destination(d_d); };

# Source additional configuration files (.conf extension only)
@include "/etc/syslog-ng/conf.d/*.conf"

# vim:ft=syslog-ng:ai:si:ts=4:sw=4:et:
```
</details>

```diff
- Note: don't forget changing the version number on the conf file from backup file and restart the service
```

 Restart Syslog-ng
 ```
 systemctl restart syslog-ng
 ```

### Log Rotation
 
```
crontab -e
```
 
```
0 5 * * * find /var/log/syslog-ng/networks/ -type f -name \*.log -mtime +7 -exec rm {} \;
0 5 * * * find /var/log/syslog-ng/security/ -type f -name \*.log -mtime +7 -exec rm {} \;
0 5 * * * find /var/log/syslog-ng/default/ -type f -name \*.log -mtime +7 -exec rm {} \;
```
</details>




Splunk Connect for Syslog (SC4S)
----------
[Link](https://splunk.github.io/splunk-connect-for-syslog/main/)

### Index Configuration (Indexer Server)
SC4S is pre-configured to map each sourcetype to a typical index. For new installations, it is best practice to create them in Splunk when using the SC4S defaults. SC4S can be easily customized to use different indexes if desired.
- email
- epav
- epintel
- infraops
- netauth
- netdlp
- netdns
- netfw
- netids
- netlb
- netops
- netwaf
- netproxy
- netipam
- oswin
- oswinsec
- osnix
- print
- em_metrics (Optional opt-in for SC4S operational metrics; ensure this is created as a **metrics** index)

### Configure Splunk HTTP Event Collector (Indexer Server)
- **Create a New Token:**
   - Name: SC4S
   - Options: Default settings

### Install Related Splunk Apps (Search Head & Indexer Server)
Install the [IT Essentials Work](https://splunkbase.splunk.com/app/5403) app using the following commands:

```bash
/opt/splunk/bin/splunk stop
tar -xvf it-essentials-work_<version>.spl -C /opt/splunk/etc/apps
chown -R splunk:splunk /opt/splunk
/opt/splunk/bin/splunk start
```

### Install and Configure SC4S (Syslog Server)
Set the host OS kernel to match the default receiver buffer of SC4S, which is set to 16MB.

a. Add the following to /etc/sysctl.conf:
```
net.core.rmem_default = 17039360
net.core.rmem_max = 17039360
```
b. Apply to the kernel:
```
sysctl -p
```

Ensure the kernel is not dropping packets:
```
netstat -su | grep "receive errors"
```
SC4S Setup
```
touch SC4S-Splunk-Connect-for-Syslog.sh
chmod +x SC4S-Splunk-Connect-for-Syslog.sh
nano SC4S-Splunk-Connect-for-Syslog.sh
```
Modify the following values prior to running the script:
- HEC_URL
- HEC_TOKEN
```
#!/bin/bash

###########
# https://splunk.github.io/splunk-connect-for-syslog/main/gettingstarted/
# https://github.com/splunk/splunk-connect-for-syslog
# https://raw.githubusercontent.com/J-C-B/community-splunk-scripts/master/SC4S-Splunk-Connect-for-Syslog-centos8.sh
###########

# Set URL and Tokens here
HEC_URL="https://192.168.1.50:8088"
HEC_TOKEN="7e92d326-408e-4679-aa50-c3c7c407f151"

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

dnf install -y conntrack podman crun

echo "
[Unit]
Description=SC4S Container
Wants=NetworkManager.service network-online.target
After=NetworkManager.service network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Environment=\"SC4S_IMAGE=ghcr.io/splunk/splunk-connect-for-syslog/container3:latest\"

# Required mount point for syslog-ng persist data (including disk buffer)
Environment=\"SC4S_PERSIST_MOUNT=splunk-sc4s-var:/var/lib/syslog-ng\"

# Optional mount point for local overrides and configurations; see notes in docs
Environment=\"SC4S_LOCAL_MOUNT=/opt/sc4s/local:/etc/syslog-ng/conf.d/local:z\"

# Optional mount point for local disk archive (EWMM output) files
Environment=\"SC4S_ARCHIVE_MOUNT=/opt/sc4s/archive:/var/lib/syslog-ng/archive:z\"

# Map location of TLS custom TLS
Environment=\"SC4S_TLS_MOUNT=/opt/sc4s/tls:/etc/syslog-ng/tls:z\"

TimeoutStartSec=0

ExecStartPre=/usr/bin/podman pull \$SC4S_IMAGE

# Note: /usr/bin/bash will not be valid path for all OS
# when startup fails on running bash check if the path is correct
ExecStartPre=/usr/bin/bash -c \"/usr/bin/systemctl set-environment SC4SHOST=$(hostname -s)\"

ExecStart=/usr/bin/podman run \
        -e \"SC4S_CONTAINER_HOST=\${SC4SHOST}\" \
        -v \"\$SC4S_PERSIST_MOUNT\" \
        -v \"\$SC4S_LOCAL_MOUNT\" \
        -v \"\$SC4S_ARCHIVE_MOUNT\" \
        -v \"\$SC4S_TLS_MOUNT\" \
        --env-file=/opt/sc4s/env_file \
        --health-cmd="/healthcheck.sh" \\
        --health-interval=10s --health-retries=6 --health-timeout=6s \
        --network host \
        --name SC4S \
        --rm \$SC4S_IMAGE

Restart=on-abnormal
" > /lib/systemd/system/sc4s.service

podman volume create splunk-sc4s-var
mkdir -p /opt/sc4s/ /opt/sc4s/local /opt/sc4s/archive /opt/sc4s/tls

echo "
SC4S_DEST_SPLUNK_HEC_DEFAULT_URL=$HEC_URL
SC4S_DEST_SPLUNK_HEC_DEFAULT_TOKEN=$HEC_TOKEN
#SC4S_DEFAULT_TIMEZONE=Asia/Jerusalem
#Uncomment the following line if using untrusted SSL certificates
SC4S_DEST_SPLUNK_HEC_TLS_VERIFY=no
# TLS Config, for McAfee etc
SC4S_SOURCE_TLS_ENABLE=yes
SC4S_LISTEN_DEFAULT_TLS_PORT=6514
SC4S_SOURCE_TLS_OPTIONS=no-tlsv12
SC4S_SOURCE_TLS_CIPHER_SUITE=ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256
SC4S_DISABLE_DROP_INVALID_CEF=yes
SC4S_DISABLE_DROP_INVALID_VMWARE_CB_PROTECT=yes
SC4S_DISABLE_DROP_INVALID_CISCO=yes
SC4S_DISABLE_DROP_INVALID_VMWARE_VSPHERE=yes
SC4S_DISABLE_DROP_INVALID_RAW_BSD=yes
SC4S_DISABLE_DROP_INVALID_XML=yes
SC4S_DISABLE_DROP_INVALID_HPE=yes
" > /opt/sc4s/env_file

echo "${yellow}Generating Cert for TLS${reset}"
openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -subj "/C=NZ/ST=NI/L=Home/O=SC4S Name/OU=Org/CN=sc4sbuilder" -keyout /opt/sc4s/tls/server.key -out /opt/sc4s/tls/server.pem
echo "${yellow}Your /opt/sc4s/env_file looks like this${reset}"
cat /opt/sc4s/env_file
echo "${yellow}Starting SC4S - This might take a while first time as the container is downloaded${reset}"
systemctl daemon-reload 
systemctl enable sc4s
systemctl start sc4s

# Send a test event
echo "SC4S - TEST" > /dev/udp/127.0.0.1/514
sleep 10
podman logs SC4S
podman ps

# Sleep to allow TLS to come up
sleep 20
netstat -tulpn | grep LISTEN

#### Use command below and then type to test
#openssl s_client -connect localhost:6514

#### Use command below for full tls test if required (adjust as needed)
#podman run -ti drwetter/testssl.sh --severity MEDIUM --ip 127.0.0.1 sc4sbuilder:6514
```

```
./SC4S-Splunk-Connect-for-Syslog.sh
```

### Configure Additional PKI Trust Anchors (Syslog Server)
Additional trusted (private) Certificate Authorities can be added by following these steps:
- **Location:**
   Append each PEM formatted certificate to the file `/opt/sc4s/tls/trusted.pem`.

Example:
```
cat /path/to/your/certificate.pem >> /opt/sc4s/tls/trusted.pem
```

<hr>

Check podman/docker logs for errors
```
sudo podman|docker logs SC4S
```

Search on Splunk for successful installation of SC4S
```
index=* sourcetype=sc4s:events "starting up"
```

Send sample data to default udp port 514 of SC4S host
```
echo “Hello SC4S” > /dev/udp/<SC4S_ip>/514
```

[Block parser to drop events issue #2162](https://github.com/splunk/splunk-connect-for-syslog/issues/2162)
