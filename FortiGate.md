# FortiGate Application for Splunk Installation & Configuration

## Install Syslog-ng
### Syslog-ng for debian

```apt install syslog-ng```

If you face dependencies issues:
 ```
 wget -qO - https://ose-repo.syslog-ng.com/apt/syslog-ng-ose-pub.asc | sudo apt-key add -
 ```
 ```
 echo "deb https://ose-repo.syslog-ng.com/apt/ nightly ubuntu-jammy" | sudo tee -a /etc/apt/sources.list.d/syslog-ng-ose.list
 ```
 ```
 apt update
 ```
 ```
 apt install syslog-ng
 ```
 <br>
 
 [#] Enable receivng logs on port 514
 
 ```
 cp /etc/syslog-ng.conf /etc/syslog-ng.conf.bkp
 ```
 
 ```
 nano /etc/syslog-ng.conf
 ```
 
 ```
 @version:4.1
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
time_reopen (10);
create_dirs(yes);
log_fifo_size (2048);
log_msg_size(8192);
chain_hostnames (no);
use_dns (no);
use_fqdn (no);
keep_hostname (yes);
perm(0644);
dir_perm(0755);
time_reopen (10);
};
source s_syn {
#    system();
#   internal();
udp(ip(0.0.0.0) port(5514));
};
source s_syf {
#    system();
#   internal();
udp(ip(0.0.0.0) port(6514));
};
source s_syd {
#    system();
#   internal();
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
 
 [#] Log Retention
 
 ```
 crontab -e
 ```
 
 ```
0 5 * * * find /var/log/syslog-ng/networks/ -type f -name \*.log -mtime +7 -exec rm {} \;
0 5 * * * find /var/log/syslog-ng/security/ -type f -name \*.log -mtime +7 -exec rm {} \;
0 5 * * * find /var/log/syslog-ng/default/ -type f -name \*.log -mtime +7 -exec rm {} \;
 ```
 
 [#] Restart Syslog-ng
 ```
 systemctl restart syslog-ng
 ```
 
 [#] Configure FortiGate to send logs to Syslog-ng server on port 514.
 <br>
 <br>
 
 ## Splunk Universal Forwarder Configuration
 
 Add the following to ```/opt/splunkforwarder/etc/system/local/inputs.conf```
 ```
[monitor:///var/log/syslog-ng/default/<FortiGate-IP>/*.log]
sourcetype = fortigate_log
disabled = false
```

[#] Restart the Universal Forwarder
```
/opt/splunkforwarder/bin/splunk restart
```

 ### Syslog-ng for CentOS and RHEL
 https://www.syslog-ng.com/community/b/blog/posts/installing-latest-syslog-ng-on-rhel-and-other-rpm-distributions
 <br>
 <br>
 
 ## Install FortiGate Add-on for Splunk


[FortiGate Add-on for Splunk](https://splunkbase.splunk.com/app/2846)
  * You can install FortiGate Add-on for Splunk on search head, indexer, forwarder or single instance Splunk server.
 <br>
 
 ## Install FortiGate Application for Splunk

[FortiGate Application for Splunk](https://splunkbase.splunk.com/app/2800)

  * Download and install the App
  * Settings, Data models, Fortinet FOS Log, accelrate
  * ```/opt/splunk/bin/splunk restart```
  * Search & Reporting App, index=fortigate, Check for sourcetype feild (fortigate_traffic, fortigate_utm, fortigate_event)
  * Enterprise Security -> Security Domains

---

## Troubleshooting

 On the search head server, Edit ```$SPLUNK_HOME/etc/apps/Splunk_TA_fortinet_fortigate/default/props.conf```
 ```
 [fortinet]
 TRANSFORMS-force_sourcetype_fgt = force_sourcetype_fgt_traffic,force_sourcetype_fgt_utm,force_sourcetype_fgt_event
 SHOULD_LINEMERGE = false
 ```
 
 ```
 /opt/splunk/bin/splunk restart
 ```

## Resources:
 - [Splunk - Fortinet](https://lantern.splunk.com/Data_Descriptors/Fortinet) 
 - [Fortinet-Splunk-Deployment-Guide](https://www.fortinet.com/content/dam/fortinet/assets/alliances/Fortinet-Splunk-Deployment-Guide.pdf)

