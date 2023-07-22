## Installation
### CentOS
[#] CentOS 7
```
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh epel-release-latest-7.noarch.rpm
```

[#] CentOS 8
```
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
rpm -Uvh epel-release-latest-8.noarch.rpm
```

`cd /etc/yum.repos.d/`

[#] CentOS 7
```
wget https://copr.fedorainfracloud.org/coprs/czanik/syslog-ng336/repo/epel-7/czanik-syslog-ng41-epel-7.repo
```

[#] CentOS 8
```
wget https://copr.fedorainfracloud.org/coprs/czanik/syslog-ng336/repo/epel-8/czanik-syslog-ng41-epel-8.repo
```

```
dnf install syslog-ng
systemctl enable syslog-ng
systemctl start syslog-ng
```


### Debian
```
apt install syslog-ng
```

If you face dependencies issues:
```
wget -qO - https://ose-repo.syslog-ng.com/apt/syslog-ng-ose-pub.asc | sudo apt-key add -
echo "deb https://ose-repo.syslog-ng.com/apt/ nightly ubuntu-jammy" | sudo tee -a /etc/apt/sources.list.d/syslog-ng-ose.list
```
```
apt update
apt install syslog-ng
```

## Configuration
### CentOS
```
cp /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.backup
nano /etc/syslog-ng/syslog-ng.conf
```
### Debian
```
cp /etc/syslog-ng.conf /etc/syslog-ng.conf.bkp
nano /etc/syslog-ng.conf
```


## Config File
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
</details>

```diff
- Note: don't forget changing the version number on the conf file from backup file and restart the service
```

 Restart Syslog-ng
 ```
 systemctl restart syslog-ng
 ```

## Log Rotation
 
```
crontab -e
```
 
```
0 5 * * * find /var/log/syslog-ng/networks/ -type f -name \*.log -mtime +7 -exec rm {} \;
0 5 * * * find /var/log/syslog-ng/security/ -type f -name \*.log -mtime +7 -exec rm {} \;
0 5 * * * find /var/log/syslog-ng/default/ -type f -name \*.log -mtime +7 -exec rm {} \;
```

## Resources

https://splunk.github.io/splunk-connect-for-syslog/main/

https://splunkbase.splunk.com/app/4740

https://www.splunk.com/en_us/blog/tips-and-tricks/syslog-ng-and-hec-scalable-aggregated-data-collection-in-splunk.html

https://conf.splunk.com/files/2017/slides/the-critical-syslog-tricks-that-no-one-seems-to-know-about.pdf
