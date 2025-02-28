#### Enable Advanced Security Audit Policy
gpedit.msc → Computer Configuration → Windows Settings → Security Settings → Advanced Audit Policy Configuration → System Audit Policies - Local Group Policy Object.

#### Linux File Permissions
```bash
-rw-r--r-- 12 linuxize users 12.0K Apr  28 10:10 file_name
|[-][-][-]-   [------] [---]
| |  |  | |      |       |
| |  |  | |      |       +-----------> 7. Group
| |  |  | |      +-------------------> 6. Owner
| |  |  | +--------------------------> 5. Alternate Access Method
| |  |  +----------------------------> 4. Others Permissions
| |  +-------------------------------> 3. Group Permissions
| +----------------------------------> 2. Owner Permissions
+------------------------------------> 1. File Type
```
#### Rsync & SCP
```bash
# Rsync - Copy a local file to another directory
rsync -a /opt/filename.zip /tmp/
# Rsync - Sync a local directory to a remote machine
rsync -a /opt/media/ remote_user@remote_host_or_ip:/opt/media/

# SCP - Copy a local file to a remote system
scp file.txt remote_username@remote_host_or_ip:/remote/directory
# SCP - Copy a local directory recursively to a remote system
scp -r /local/directory remote_username@remote_host_or_ip:/remote/directory
```
#### Firewalld
```bash
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --permanent --add-port=9997/tcp
firewall-cmd --permanent --add-port=8089/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --permanent --add-port=514/tcp
firewall-cmd --reload
```
```bash
systemctl stop firewalld
systemctl disable firewalld
```
#### SSH logging
```bash
nano /etc/ssh/sshd_config

# Logging
SyslogFacility AUTH
LogLevel INFO

###############
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
###############
```
#### Syslog
```bash
nano /etc/syslog.conf
auth.info /var/log/sshd.log
```

| Filename | Purpose                                                          |
| -------- | ---------------------------------------------------------------- |
| auth.log | System authentication and security events                        |
| boot.log | A record of boot-related events                                  |
| dmesg    | Kernel-ring buffer events related to device drivers              |
| dpkg.log | Software package-management events                               |
| kern.log | Linux kernel events                                              |
| syslog   | A collection of all logs                                         |
| wtmp     | Tracks user sessions (accessed through the who and last commands |

| 0   | Emergency     | System is unusable                |
| --- | ------------- | --------------------------------- |
| 1   | Alert         | Action must be taken immediately  |
| 2   | Critical      | Critical conditions               |
| 3   | Error         | Error conditions                  |
| 4   | Warning       | Warning conditions                |
| 5   | Notice        | Normal but significant conditions |
| 6   | Informational | Informational messages            |
| 7   | Debug         | Debug-level messages              |
#### MISC
```bash
cat /etc/os-release
uname - a
hostnamectl set-hostname host.domain.com
hostnamectl status
dnsdomainname
timedatectl set-timezone Asia/Jerusalem
```
#### Memory Commands
```bash
free -m # (1)
free -h # (2)

dmidecode --type memory # (2)
```
#### CPU and CPU Cores Commands
```bash
nproc

(Threads x Cores) x Physical CPU Number = Number of vCPUs

lscpu 
# - Look for the following fields:
#     - CPU(s): Total number of logical CPUs (vCPUs).
#     - Core(s) per socket: Number of physical cores per CPU socket.
#     - Socket(s): Number of physical CPU sockets.
#     - Model name: CPU model and speed (e.g., `2.20 GHz`).

cat /proc/cpuinfo | grep processor | wc -l

dmidecode --type processor
```
#### Check disk type and performance
```bash
lsblk -d -o name,rota
# - rota=1: Rotational disk (HDD).
# - rota=0 Non-rotational disk (SSD).
```
#### Storage Commands
```bash
du -csh # (1)
lsblk # (2)
df -h /opt/splunk / # (3)
fdisk -l # (4)
fdisk /dev/sda # (5)
vgdisplay # (6)
```
#### Network Commands
```bash
vi /etc/sysconfig/network-scripts/ifcfg-<int> # (1)
route -n # (2)
ip a # (3)
hostname -I # (4)
tcpdump -i eth3 -n tcp and host 192.168.1.50 and (port 80 or port 443) # (5)
nc -zv <IP Address> <Port> # (6)
telnet <IP Address> <Port> # (7)
nmtui # (8)

# Check the speed of the NIC:
sudo ethtool enp2s0 | grep Speed:
```
#### Disable SELinux
```bash
sestatus
nano /etc/selinux/config
SELINUX=disabled
```
#### Disable Transparent Huge Pages (THP)
```bash
nano /etc/systemd/system/disable-thp.service
[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
```
#### NTP Commands
```bash
timedatectl
chronyc sources
nano /etc/chrony.conf
nano /etc/ntp.conf
```
#### Process Commands
```bash
pgrep
pkill
ps -elf
```
#### Permission Commands
```bash
visudo
chmod
chown
setfacl -m u:<User>:r /path/to/folder/or/files
setfacl -m g:<Group>:r /path/to/folder/or/files
```
#### Storage Options
Option 1: Resize Without Adding a New Disk

```bash
growpart /dev/sda 3
lvextend -r -l +100%FREE /dev/mapper/centos-opt
partprobe
```
OR
```bash
fdisk /dev/sda
# 1. "d" to delete the only partition /dev/sda has.
# 2. "n" to create a new one. Running "n" will make fdisk interactively ask you some parameters for partition creation, you can just hit enter so it uses the default values.
# 3. Running the previous command does not write the changes to disk, to do this, you need to run the "w" command.
partprobe
lsblk
xfs_growfs /dev/sda1
```

Option 2: Resize by Adding a New Disk

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
#### Crontab
[Crontab Guru](https://crontab.guru/)
Crontab is a time-based job scheduling program used in Unix-like operating systems to schedule recurring tasks or jobs. The name "crontab" comes from "cron," the daemon (background process) that runs scheduled tasks, and "tab," which is short for "table" since the scheduling information is organized in tabular form.

With crontab, users can schedule scripts, commands, or programs to run at specified intervals or times, such as daily, weekly, monthly, or even at specific minutes within an hour. This makes it particularly useful for automating repetitive tasks, maintenance activities, or any operation that needs to be executed on a regular basis.

The crontab file follows a specific format.

```bash
# <Minute> <Hour> <Day of Month> <Month> <Day of Week> Command
```

Each line in the crontab file represents a scheduled task or command. Here's a breakdown of the different fields:
- Minute: Specifies the minute(s) at which the task should run. Valid values are 0 to 59.
- Hour: Specifies the hour(s) at which the task should run. Valid values are 0 to 23.
- Day of Month: Specifies the day(s) of the month when the task should run. Valid values are 1 to 31.
- Month: Specifies the month(s) when the task should run. Valid values are 1 to 12 or their corresponding names (e.g., Jan, Feb, etc.).
- Day of Week: Specifies the day(s) of the week when the task should run. Valid values are 0 to 7 or their corresponding names (0 or 7 represents Sunday).
- Command: The actual command or script to be executed at the specified time and date.

To schedule a task, you need to add a line to your crontab file following this format. Each field is separated by spaces or tabs, and you can use asterisks (*) to represent any value.

Remember to run the `crontab -e` command to edit the crontab file for the current user.
