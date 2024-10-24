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

<details>
 <summary>SC4S Dashboard</summary>

```
<form version="1.1" theme="dark">
  <label>SC4S Metrics and Events Dashboard</label>
  <description>Monitor SC4S instances connected to this Splunk instance.</description>
  <search id="baseMetricsSearch">
    <query>
      | mstats 
      max("spl.sc4syslog.center.received.processed")
      max("spl.sc4syslog.dst.dropped")
      max("spl.sc4syslog.dst.queued")
      prestats=true
      WHERE "index"="_metrics"
      BY sc4s_container
      span=$span$
    </query>
    <earliest>$time_range.earliest$</earliest>
    <latest>$time_range.latest$</latest>
    <sampleRatio>1</sampleRatio>
  </search>
  <search id="baseEventsSearch">
    <query>
    index=* sc4s_container=$sc4s_instance$
    </query>
    <earliest>$time_range.earliest$</earliest>
    <latest>$time_range.latest$</latest>
    <sampleRatio>1</sampleRatio>
  </search>
  <fieldset submitButton="false"></fieldset>
  <row>
    <panel>
      <input type="dropdown" token="span" searchWhenChanged="true">
        <label>Span</label>
        <choice value="30s">30s</choice>
        <choice value="1m">1m</choice>
        <choice value="3m">3m</choice>
        <choice value="30m">30m</choice>
        <choice value="1h">1h</choice>
        <choice value="6h">6h</choice>
        <choice value="12h">12h</choice>
        <choice value="1d">1d</choice>
        <default>30s</default>
        <initialValue>30s</initialValue>
      </input>
      <input type="time" token="time_range">
        <label>Timer</label>
        <default>
          <earliest>rt-15m</earliest>
          <latest>rt</latest>
        </default>
      </input>
      <html>
        <p>Choose time interval and window.</p>
        <p>By default, the dashboard loads metrics every 30 seconds for the duration of the 15-minute window.</p>
        <p>By default, the dashboard loads events for the duration of 15-minutes window if the SC4S instance name is provided.</p>
      </html>
    </panel>
  </row>
  <row>
    <panel>
      <html>
      <h1>
        Metrics
      </h1>
      </html>
    </panel>
  </row>
  <row>
    <panel>
      <title>Received Messages</title>
      <html>
        <p>Healthy SC4S instance logs the number of received messages each 30 seconds.</p>
        <p>The number should grow by at least 1 every 30 seconds. This is because the metrics message counts as a received message.</p>
        <p>This cumulative sum grows until the SC4S instance restarts.</p>
      </html>
      <chart>
        <search base="baseMetricsSearch">
          <query>
            | timechart max("spl.sc4syslog.center.received.processed") span=$span$ useother=false BY sc4s_container
            WHERE max in top1000
            | fields - _span*
          </query>
        </search>
        <option name="charting.axisLabelsX.majorLabelStyle.overflowMode">ellipsisNone</option>
        <option name="charting.axisLabelsX.majorLabelStyle.rotation">0</option>
        <option name="charting.axisTitleX.visibility">visible</option>
        <option name="charting.axisTitleY.visibility">visible</option>
        <option name="charting.axisTitleY2.visibility">visible</option>
        <option name="charting.axisX.abbreviation">none</option>
        <option name="charting.axisX.scale">linear</option>
        <option name="charting.axisY.abbreviation">auto</option>
        <option name="charting.axisY.includeZero">1</option>
        <option name="charting.axisY.scale">log</option>
        <option name="charting.axisY2.abbreviation">none</option>
        <option name="charting.axisY2.enabled">0</option>
        <option name="charting.axisY2.scale">inherit</option>
        <option name="charting.chart">line</option>
        <option name="charting.chart.bubbleMaximumSize">50</option>
        <option name="charting.chart.bubbleMinimumSize">10</option>
        <option name="charting.chart.bubbleSizeBy">area</option>
        <option name="charting.chart.nullValueMode">zero</option>
        <option name="charting.chart.showDataLabels">minmax</option>
        <option name="charting.chart.sliceCollapsingThreshold">0.01</option>
        <option name="charting.chart.stackMode">default</option>
        <option name="charting.chart.style">shiny</option>
        <option name="charting.drilldown">none</option>
        <option name="charting.gridLinesX.showMajorLines">1</option>
        <option name="charting.layout.splitSeries">1</option>
        <option name="charting.layout.splitSeries.allowIndependentYRanges">1</option>
        <option name="charting.legend.labelStyle.overflowMode">ellipsisMiddle</option>
        <option name="charting.legend.mode">seriesCompare</option>
        <option name="charting.legend.placement">right</option>
        <option name="charting.lineWidth">2</option>
        <option name="trellis.enabled">0</option>
        <option name="trellis.scales.shared">1</option>
        <option name="trellis.size">medium</option>
      </chart>
    </panel>
    <panel>
      <title>Dropped Messages by SC4S Instance</title>
      <html>
        <p>This is a cumulative sum that, in the absence of dropped messages, remains at a constant level of 0.</p>
        <p>Upon restarting the SC4S instance, it is reset back to 0.</p>
        <p>This does not include potential UDP messages dropped from the port buffer.</p>
      </html>
      <chart>
        <search base="baseMetricsSearch">
          <query>
            | timechart max("spl.sc4syslog.dst.dropped") span=$span$ useother=false BY sc4s_container WHERE max in top1000
            | fields - _span*
          </query>
        </search>
        <option name="charting.axisLabelsX.majorLabelStyle.overflowMode">ellipsisNone</option>
        <option name="charting.axisLabelsX.majorLabelStyle.rotation">0</option>
        <option name="charting.axisTitleX.visibility">visible</option>
        <option name="charting.axisTitleY.visibility">visible</option>
        <option name="charting.axisTitleY2.visibility">visible</option>
        <option name="charting.axisX.abbreviation">none</option>
        <option name="charting.axisX.scale">linear</option>
        <option name="charting.axisY.abbreviation">auto</option>
        <option name="charting.axisY.includeZero">1</option>
        <option name="charting.axisY.scale">log</option>
        <option name="charting.axisY2.abbreviation">none</option>
        <option name="charting.axisY2.enabled">0</option>
        <option name="charting.axisY2.scale">inherit</option>
        <option name="charting.chart">line</option>
        <option name="charting.chart.bubbleMaximumSize">50</option>
        <option name="charting.chart.bubbleMinimumSize">10</option>
        <option name="charting.chart.bubbleSizeBy">area</option>
        <option name="charting.chart.nullValueMode">zero</option>
        <option name="charting.chart.showDataLabels">minmax</option>
        <option name="charting.chart.sliceCollapsingThreshold">0.01</option>
        <option name="charting.chart.stackMode">default</option>
        <option name="charting.chart.style">shiny</option>
        <option name="charting.drilldown">none</option>
        <option name="charting.gridLinesX.showMajorLines">1</option>
        <option name="charting.layout.splitSeries">1</option>
        <option name="charting.layout.splitSeries.allowIndependentYRanges">1</option>
        <option name="charting.legend.labelStyle.overflowMode">ellipsisMiddle</option>
        <option name="charting.legend.mode">seriesCompare</option>
        <option name="charting.legend.placement">right</option>
        <option name="charting.lineWidth">2</option>
        <option name="trellis.enabled">0</option>
        <option name="trellis.scales.shared">1</option>
        <option name="trellis.size">medium</option>
      </chart>
    </panel>
  </row>
  <row>
    <panel>
      <title>SC4S Instance</title>
      <input type="dropdown" token="sc4s_instance" searchWhenChanged="true">
        <label>To view details, choose one of the SC4S instances used in the defined time window.</label>
        <fieldForLabel>values(sc4s_container)</fieldForLabel>
        <fieldForValue>values(sc4s_container)</fieldForValue>
        <search>
          <query>| mcatalog values(sc4s_container) WHERE index=_metrics | mvexpand values(sc4s_container)</query>
          <earliest>0</earliest>
          <latest></latest>
        </search>
      </input>
    </panel>
    <panel>
      <title>Instance name</title>
      <single>
        <search>
          <query>| mcatalog values(sc4s_container) WHERE index=_metrics AND sc4s_container=$sc4s_instance$ | mvexpand values(sc4s_container)</query>
          <earliest>0</earliest>
          <latest></latest>
        </search>
        <option name="colorBy">value</option>
        <option name="colorMode">none</option>
        <option name="drilldown">none</option>
        <option name="height">71</option>
        <option name="numberPrecision">0</option>
        <option name="rangeColors">["0x53a051", "0x0877a6", "0xf8be34", "0xf1813f", "0xdc4e41"]</option>
        <option name="rangeValues">[0,30,70,100]</option>
        <option name="showSparkline">1</option>
        <option name="showTrendIndicator">1</option>
        <option name="trellis.enabled">0</option>
        <option name="trellis.scales.shared">1</option>
        <option name="trellis.size">medium</option>
        <option name="trendColorInterpretation">standard</option>
        <option name="trendDisplayMode">absolute</option>
        <option name="unitPosition">after</option>
        <option name="useColors">0</option>
        <option name="useThousandSeparators">1</option>
      </single>
    </panel>
    <panel>
      <title>SC4S version</title>
      <single>
        <search>
          <query>| mcatalog values(sc4s_version) WHERE index=_metrics AND sc4s_container=$sc4s_instance$ | mvexpand values(sc4s_version)</query>
          <earliest>0</earliest>
          <latest></latest>
        </search>
        <option name="colorBy">value</option>
        <option name="colorMode">none</option>
        <option name="drilldown">none</option>
        <option name="height">71</option>
        <option name="numberPrecision">0</option>
        <option name="rangeColors">["0x53a051", "0x0877a6", "0xf8be34", "0xf1813f", "0xdc4e41"]</option>
        <option name="rangeValues">[0,30,70,100]</option>
        <option name="showSparkline">1</option>
        <option name="showTrendIndicator">1</option>
        <option name="trellis.enabled">0</option>
        <option name="trellis.scales.shared">1</option>
        <option name="trellis.size">medium</option>
        <option name="trendColorInterpretation">standard</option>
        <option name="trendDisplayMode">absolute</option>
        <option name="unitPosition">after</option>
        <option name="useColors">0</option>
        <option name="useThousandSeparators">1</option>
      </single>
    </panel>
  </row>
  <row>
    <panel>
      <html>
        <h2>
        Messages' metrics
        </h2>
        <p>The delta is negative at the moment of instance restart.</p>
      </html>
    </panel>
  </row>
  <row>
    <panel>
      <chart>
        <search base="baseMetricsSearch">
          <query>
            | search sc4s_container=$sc4s_instance$
            | timechart
            max("spl.sc4syslog.center.received.processed") AS received_cumulative_sum
            max("spl.sc4syslog.dst.dropped") AS dropped_cumulative_sum
            max("spl.sc4syslog.dst.queued") AS queued
            span=$span$
            | delta received_cumulative_sum as received
            | delta dropped_cumulative_sum as dropped
            | where not (received_cumulative_sum == received AND dropped_cumulative_sum == dropped)
            | fields - _span* received_cumulative_sum dropped_cumulative_sum
          </query>
        </search>
        <option name="charting.axisLabelsX.majorLabelStyle.overflowMode">ellipsisNone</option>
        <option name="charting.axisLabelsX.majorLabelStyle.rotation">0</option>
        <option name="charting.axisTitleX.visibility">visible</option>
        <option name="charting.axisTitleY.visibility">visible</option>
        <option name="charting.axisTitleY2.visibility">visible</option>
        <option name="charting.axisX.abbreviation">none</option>
        <option name="charting.axisX.scale">linear</option>
        <option name="charting.axisY.abbreviation">none</option>
        <option name="charting.axisY.scale">linear</option>
        <option name="charting.axisY2.abbreviation">none</option>
        <option name="charting.axisY2.enabled">0</option>
        <option name="charting.axisY2.scale">inherit</option>
        <option name="charting.chart">area</option>
        <option name="charting.chart.bubbleMaximumSize">50</option>
        <option name="charting.chart.bubbleMinimumSize">10</option>
        <option name="charting.chart.bubbleSizeBy">area</option>
        <option name="charting.chart.nullValueMode">gaps</option>
        <option name="charting.chart.overlayFields">queued</option>
        <option name="charting.chart.showDataLabels">minmax</option>
        <option name="charting.chart.sliceCollapsingThreshold">0.01</option>
        <option name="charting.chart.stackMode">default</option>
        <option name="charting.chart.style">shiny</option>
        <option name="charting.drilldown">none</option>
        <option name="charting.layout.splitSeries">0</option>
        <option name="charting.layout.splitSeries.allowIndependentYRanges">0</option>
        <option name="charting.legend.labelStyle.overflowMode">ellipsisMiddle</option>
        <option name="charting.legend.mode">standard</option>
        <option name="charting.legend.placement">right</option>
        <option name="charting.lineWidth">2</option>
        <option name="trellis.enabled">0</option>
        <option name="trellis.scales.shared">1</option>
        <option name="trellis.size">medium</option>
      </chart>
    </panel>
  </row>
  <row>
    <panel>
      <html>
        <h1>
          Events
        </h1>
      </html>
    </panel>
  </row>
  <row>
    <panel>
      <title>Total number of events</title>
      <single>
        <title>Total volume of actual syslog traffic delivered by this SC4S instance to Splunk</title>
        <search base="baseEventsSearch">
          <query>| stats count</query>
        </search>
        <option name="colorBy">value</option>
        <option name="colorMode">none</option>
        <option name="drilldown">none</option>
        <option name="numberPrecision">0</option>
        <option name="rangeColors">["0x53a051", "0x0877a6", "0xf8be34", "0xf1813f", "0xdc4e41"]</option>
        <option name="rangeValues">[0,30,70,100]</option>
        <option name="showSparkline">1</option>
        <option name="showTrendIndicator">1</option>
        <option name="trellis.enabled">0</option>
        <option name="trellis.scales.shared">1</option>
        <option name="trellis.size">medium</option>
        <option name="trendColorInterpretation">standard</option>
        <option name="trendDisplayMode">absolute</option>
        <option name="unitPosition">after</option>
        <option name="useColors">0</option>
        <option name="useThousandSeparators">1</option>
      </single>
    </panel>
  </row>
  <row>
    <panel>
      <title>Distributions of events by index</title>
      <chart>
        <search base="baseEventsSearch">
          <query>| stats count by index</query>
        </search>
        <option name="charting.axisLabelsX.majorLabelStyle.overflowMode">ellipsisNone</option>
        <option name="charting.axisLabelsX.majorLabelStyle.rotation">0</option>
        <option name="charting.axisTitleX.visibility">visible</option>
        <option name="charting.axisTitleY.visibility">visible</option>
        <option name="charting.axisTitleY2.visibility">visible</option>
        <option name="charting.axisX.abbreviation">none</option>
        <option name="charting.axisX.scale">linear</option>
        <option name="charting.axisY.abbreviation">none</option>
        <option name="charting.axisY.scale">linear</option>
        <option name="charting.axisY2.abbreviation">none</option>
        <option name="charting.axisY2.enabled">0</option>
        <option name="charting.axisY2.scale">inherit</option>
        <option name="charting.chart">pie</option>
        <option name="charting.chart.bubbleMaximumSize">50</option>
        <option name="charting.chart.bubbleMinimumSize">10</option>
        <option name="charting.chart.bubbleSizeBy">area</option>
        <option name="charting.chart.nullValueMode">gaps</option>
        <option name="charting.chart.showDataLabels">none</option>
        <option name="charting.chart.sliceCollapsingThreshold">0.01</option>
        <option name="charting.chart.stackMode">default</option>
        <option name="charting.chart.style">shiny</option>
        <option name="charting.drilldown">none</option>
        <option name="charting.layout.splitSeries">0</option>
        <option name="charting.layout.splitSeries.allowIndependentYRanges">0</option>
        <option name="charting.legend.labelStyle.overflowMode">ellipsisMiddle</option>
        <option name="charting.legend.mode">standard</option>
        <option name="charting.legend.placement">right</option>
        <option name="charting.lineWidth">2</option>
        <option name="trellis.enabled">0</option>
        <option name="trellis.scales.shared">1</option>
        <option name="trellis.size">medium</option>
      </chart>
    </panel>
    <panel>
      <title>Trends of events by index</title>
      <table>
        <search base="baseEventsSearch">
          <query>| chart sparkline(count) AS "Indexes Trend" count AS Total BY index</query>
        </search>
        <option name="count">20</option>
        <option name="dataOverlayMode">none</option>
        <option name="drilldown">none</option>
        <option name="percentagesRow">false</option>
        <option name="rowNumbers">false</option>
        <option name="totalsRow">false</option>
        <option name="wrap">false</option>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <title>Data parsers</title>
      <chart>
        <search>
          <query>
          index=* sc4s_container=$sc4s_instance$ | eval tags=split(sc4s_tags,"|") | mvexpand tags | search tags=".app.*" | timechart count by tags
          </query>
          <earliest>$time_range.earliest$</earliest>
          <latest>$time_range.latest$</latest>
          <sampleRatio>1</sampleRatio>
        </search>
        <option name="charting.axisLabelsX.majorLabelStyle.overflowMode">ellipsisNone</option>
        <option name="charting.axisLabelsX.majorLabelStyle.rotation">0</option>
        <option name="charting.axisTitleX.visibility">visible</option>
        <option name="charting.axisTitleY.visibility">visible</option>
        <option name="charting.axisTitleY2.visibility">visible</option>
        <option name="charting.axisX.abbreviation">none</option>
        <option name="charting.axisX.scale">linear</option>
        <option name="charting.axisY.abbreviation">none</option>
        <option name="charting.axisY.scale">linear</option>
        <option name="charting.axisY2.abbreviation">none</option>
        <option name="charting.axisY2.enabled">0</option>
        <option name="charting.axisY2.scale">inherit</option>
        <option name="charting.chart">area</option>
        <option name="charting.chart.bubbleMaximumSize">50</option>
        <option name="charting.chart.bubbleMinimumSize">10</option>
        <option name="charting.chart.bubbleSizeBy">area</option>
        <option name="charting.chart.nullValueMode">gaps</option>
        <option name="charting.chart.showDataLabels">none</option>
        <option name="charting.chart.sliceCollapsingThreshold">0.01</option>
        <option name="charting.chart.stackMode">default</option>
        <option name="charting.chart.style">shiny</option>
        <option name="charting.drilldown">none</option>
        <option name="charting.layout.splitSeries">0</option>
        <option name="charting.layout.splitSeries.allowIndependentYRanges">0</option>
        <option name="charting.legend.labelStyle.overflowMode">ellipsisMiddle</option>
        <option name="charting.legend.mode">standard</option>
        <option name="charting.legend.placement">right</option>
        <option name="charting.lineWidth">2</option>
        <option name="trellis.enabled">0</option>
        <option name="trellis.scales.shared">1</option>
        <option name="trellis.size">medium</option>
      </chart>
    </panel>
  </row>
  <row>
    <panel>
      <title>Tags</title>
      <table>
        <search>
          <query>
          index=* sc4s_container=$sc4s_instance$ | eval tags=split(sc4s_tags,"|") | mvexpand tags | chart count by tags
          </query>
          <earliest>$time_range.earliest$</earliest>
          <latest>$time_range.latest$</latest>
          <sampleRatio>1</sampleRatio>
        </search>
        <option name="drilldown">none</option>
      </table>
    </panel>
  </row>
</form>
```
</details>

<details>
 <summary>Block parser to drop events</summary>

nano /opt/sc4s/local/config/app_parsers/vmware_vsphere_block_sourcetype-postfilter.conf [Link](https://github.com/splunk/splunk-connect-for-syslog/issues/2553#issuecomment-2298332073)
```
block parser vmware_vsphere_block_sourcetype-postfilter() {
    channel {
        rewrite(r_set_dest_splunk_null_queue);
   };
};
application vmware_vsphere_block_sourcetype-postfilter[sc4s-postfilter] {
 filter {
        "${fields.sc4s_vendor}" eq "vmware" and
        not (
            match("vmware:vclog:vpxd", value('.splunk.sourcetype'), type(string)) or
            match("vmware:vclog:vpxd-main", value('.splunk.sourcetype'), type(string)) or
            match("vclog:applmgmt-audit", value('.splunk.sourcetype'), type(string)) or
            match("vmware:vclog:vmafdd", value('.splunk.sourcetype'), type(string)) or
            match("vmware:vclog:vpxd-svcs-access", value('.splunk.sourcetype'), type(string)) or
            match("vmware:esxlog:vmkernel", value('.splunk.sourcetype'), type(string)) or
            match("vmware:esxlog:hostd", value('.splunk.sourcetype'), type(string)) or
            match("vmware:esxlog:vmauthd", value('.splunk.sourcetype'), type(string))
        )
    };
    parser { vmware_vsphere_block_sourcetype-postfilter(); };
};
```
nano /opt/sc4s/local/config/app_parsers/vmware_vsphere_sps-postfilter.conf [Link](https://github.com/splunk/splunk-connect-for-syslog/issues/1644#issuecomment-1096762979)
```
block parser vmware_vsphere_sps-postfilter() {
    channel {
        rewrite {
		r_set_splunk_dest_update(
			vendor('null') product('queue')
		);
        };
   };
};

application vmware_vsphere_sps-postfilter[sc4s-postfilter] {
 filter {
        program("sps")
    };
    parser { vmware_vsphere_sps-postfilter(); };
};
```

</details>
