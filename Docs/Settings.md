## IOPS test command for linux
```
dnf install -y fio
fio --name=benchmark --size=1G --runtime=30 --filename=tempfile --ioengine=libaio --rw=randread --iodepth=32
```
## Useful commands
```
# System info
nmtui
lscpu
uname - a
free -m
hostnamectl
timedatectl

# Storage
du -csh
lsblk
df -h /
fdisk -l
fdisk /dev/sda
vgdisplay

# Network
route -n
ip a

# Process
pgrep
pkill
ps -elf

# Permissions
visudo
chmod
chown
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
