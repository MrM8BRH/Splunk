## Enable SSHD logging
```
nano /etc/ssh/sshd_config

# Logging
SyslogFacility AUTH
LogLevel INFO

##################
# SysLogFacility #
#- DAEMON        #
#- USER          #
#- AUTH          #
#- LOCAL0        #
#- LOCAL1        #
#- LOCAL2        #
#- LOCAL3        #
#- LOCAL4        #
#- LOCAL5        #
#- LOCAL6        #
#- LOCAL7        #
##################
# Ref:
# → https://docs.ssh.com/manuals/server-zos-admin/54/Configuring_Logging_in_sshd2.html
# → https://docs.ssh.com/manuals/server-zos-admin/65/Server-auditing-SysLogFacility.html
```
![Screenshot-2023-07-19-at-5 48 42-PM](https://github.com/user-attachments/assets/c8180d9c-d4df-40a2-8582-19f6ae822971)

## Linux File Permissions
![linux-introduction-file-permissions-4-2054323870](https://github.com/user-attachments/assets/8722f39f-da28-4b0a-b8e0-e1946aacced1)
![image](https://github.com/user-attachments/assets/14b48a1b-e53f-4340-a764-664078966f56)

## Enable Advanced Security Audit Policy
![gedit](https://github.com/user-attachments/assets/083b597c-b467-4159-a889-9d71dbf6c22c)


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

/sbin/sysctl -p  # Command load kernel settings from /etc/sysctl.conf. 
```

## Storage Options

[Extending a logical volume in a virtual machine running Red Hat or Cent OS](https://kb.vmware.com/s/article/1006371)

### Option 1: Resize Without Adding a New Disk

```
growpart /dev/sda 3
lvextend -r -l +100%FREE /dev/mapper/centos-opt
partprobe
```
OR
```
fdisk /dev/sda
1. "d" to delete the only partition /dev/sda has.
2. "n" to create a new one. Running "n" will make fdisk interactively ask you some parameters for partition creation, you can just hit enter so it uses the default values.
3. Running the previous command does not write the changes to disk, to do this, you need to run the "w" command.
partprobe
lsblk
xfs_growfs /dev/sda1
```


### Option 2: Resize by Adding a New Disk

```
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
