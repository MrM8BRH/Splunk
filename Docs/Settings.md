## Extending a logical volume in a virtual machine running Red Hat or Cent OS
https://kb.vmware.com/s/article/1006371

## Change Timezone
```
timedatectl
timedatectl set-timezone Asia/Jerusalem
```
## Change Hostname
```
hostname
hostnamectl set-hostname <hostname>
```

## Change IP Address, DNS Server, Gateway
*   `ip a`
*   `vi /etc/sysconfig/network-scripts/ifcfg-<int>`
  
```
ONBOOT=yes
IPADDR=<IP>                                       *****
PREFIX=                                           *****
GATEWAY=<GW>                                      *****
DNS1=<DNS1>                                       *****
DNS2=<DNS2>                                       *****
```
*   `systemctl restart network.service`

## Change NTP Server

### chronyd
```
systemctl status chronyd
systemctl start chronyd
systemctl enable chronyd
```

### NTP
```
dnf install ntp
systemctl start ntp
systemctl enable ntp
```

*   `nano /etc/ntp.conf`

*   server "IP Address"
  
```
systemctl restart ntpd
ntpq -p
```
