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

## Storage Options

[Extending a logical volume in a virtual machine running Red Hat or Cent OS](https://kb.vmware.com/s/article/1006371)

### Option 1: Resize Without Adding a New Disk

```bash
# Resize the partition
parted /dev/sda
resizepart 2  # /dev/sda(2)
End? [48.0GB]? 48.0+[new]GB
q

# Resize physical volume and logical volume
pvresize /dev/sda2
lvextend -r -l +100%FREE /dev/mapper/centos-opt
partprobe
```

### Option 2: Resize by Adding a New Disk

```bash
# Create physical volume on the new disk
pvcreate /dev/sda

# Display volume group information
vgdisplay

# Extend volume group with the new disk
vgextend <VG Name> /dev/sda

# Resize logical volume
lvextend -r -l +100%FREE /dev/mapper/<VG Name>-opt

# Update partition information
partprobe
```
