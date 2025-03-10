#### Enable Advanced Security Audit Policy
gpedit.msc → Computer Configuration → Windows Settings → Security Settings → Advanced Audit Policy Configuration → System Audit Policies - Local Group Policy Object.

#### Power
```
# View the available CPU speed governors for the first CPU core
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 
# Output example: performance powersave

# Check the current CPU governor in use for the first CPU core
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# Output example: powersave

# Change the CPU governor to 'performance' mode for all CPU cores
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# This command sets the scaling governor to 'performance' for all CPU cores
```
#### BIOS & Firmware Version
```
# Display BIOS information from the system's DMI (Desktop Management Interface) data
sudo dmidecode -t bios
```
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
firewall-cmd --permanent --remove-port=8000/tcp
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
# Display the contents of the /etc/os-release file to show OS information
cat /etc/os-release

# Display system information including the kernel version and architecture
uname -a

# Set the system's hostname to 'host.domain.com'
hostnamectl set-hostname host.domain.com

# Show the current status of the hostname and related settings
hostnamectl status

# Display the DNS domain name of the system
dnsdomainname

# Set the system's timezone to Asia/Jerusalem
timedatectl set-timezone Asia/Jerusalem
```
#### Memory Commands
```bash
# Display memory usage in megabytes
free -m

# Display memory usage in a human-readable format (e.g., KB, MB, GB)
free -h

# Display detailed information about the system's memory (RAM) using DMI data
dmidecode --type memory
```
#### CPU & Processes Commands
```bash
# Display a dynamic real-time view of system processes and resource usage
top

# Display an enhanced version of top with a more user-friendly interface
htop

# Display system and process information, including resource usage over time
atop

# Search for processes by name and return their process IDs
pgrep

# Kill processes by name using their process IDs
pkill

# Display detailed information about all running processes
ps -elf

# Identify processes that are accessing a specific file (e.g., ~/testfile.txt)
fuser ~/testfile.txt

# Display the number of processing units available to the current process
nproc

# Display the total number of processing units available, including all cores and threads
nproc --all

# Calculate the number of virtual CPUs (vCPUs) based on the formula provided
# (Threads x Cores) x Physical CPU Number = Number of vCPUs

# Display detailed information about the CPU architecture and configuration
lscpu 
# Look for the following fields:
#     - CPU(s): Total number of logical CPUs (vCPUs).
#     - Core(s) per socket: Number of physical cores per CPU socket.
#     - Socket(s): Number of physical CPU sockets.
#     - Model name: CPU model and speed (e.g., `2.20 GHz`).

# Count the number of logical processors (vCPUs) available on the system
cat /proc/cpuinfo | grep processor | wc -l

# Display detailed information about the system's processors using DMI data
dmidecode --type processor
```
#### Storage Commands
```bash
# Display the total disk usage of the current directory and its subdirectories in a human-readable format
du -csh

# List all block devices, including partitions and their mount points
lsblk

# Display disk space usage for the specified directories (/opt/splunk and /) in a human-readable format
df -h /opt/splunk /

# List all disk partitions and their details
fdisk -l

# Open the fdisk utility to manage partitions on the specified disk (/dev/sda)
fdisk /dev/sda

# Display information about volume groups in the Logical Volume Manager (LVM)
vgdisplay

# Display real-time I/O usage by processes
iotop #

# Check the type of disk (rotational or non-rotational) and its performance
lsblk -d -o name,rota
### - rota=1: Rotational disk (HDD).
### - rota=0: Non-rotational disk (SSD).
```
#### Network Commands
```bash
# Open the network interface configuration file for the specified interface in the vi editor
vi /etc/sysconfig/network-scripts/ifcfg-<int>

# Display the kernel routing table in a numeric format
route -n

# Show all network interfaces and their current IP addresses
ip a

# Display the IP addresses assigned to the host
hostname -I #

# Capture and display TCP packets on interface eth3 for the specified host and ports (80 and 443)
tcpdump -i eth3 -n tcp and host 192.168.1.50 and (port 80 or port 443)

# Check if a specific port is open on a given IP address using netcat
nc -zv <IP Address> <Port>

# Connect to a specific IP address and port using telnet
telnet <IP Address> <Port>

# Open the NetworkManager TUI (Text User Interface) for managing network connections
nmtui

# Check the speed of the network interface card (NIC) for the specified interface
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

```
systemctl daemon-reload
systemctl start disable-thp
systemctl enable disable-thp
```
#### NTP Commands
```bash
# Display the current system time, timezone, and NTP synchronization status
timedatectl

# Display the sources that chrony is using for time synchronization
chronyc sources

# Open the chrony configuration file in the nano text editor for editing
nano /etc/chrony.conf

# Open the NTP configuration file in the nano text editor for editing
nano /etc/ntp.conf
```
#### Permission Commands
```bash
# Open the sudoers file for editing with the visudo command
visudo

# Change the permissions of a file or directory (usage example: chmod 755 filename)
chmod

# Change the ownership of a file or directory (usage example: chown user:group filename)
chown

# Modify the Access Control List (ACL) to give a specific user read permission on a folder or file
setfacl -m u:<User>:r /path/to/folder/or/files

# Modify the Access Control List (ACL) to give a specific group read permission on a folder or file
setfacl -m g:<Group>:r /path/to/folder/or/files
```
#### Storage Options
Option 1: Resize Without Adding a New Disk
```bash
# Resize the specified partition (3rd partition on /dev/sda) to fill the available space
growpart /dev/sda 3

# Extend the logical volume 'opt' to use all available free space in the volume group, and resize the filesystem
lvextend -r -l +100%FREE /dev/mapper/centos-opt

# Inform the operating system of partition table changes (useful after modifying partitions)
partprobe
```
OR
```bash
# Open the fdisk utility to manage partitions on the specified disk (/dev/sda)
fdisk /dev/sda

# Inside fdisk:
# 1. Press "d" to delete the only partition on /dev/sda.
# 2. Press "n" to create a new partition. Follow the prompts and hit enter to accept the default values.
# 3. After making changes, press "w" to write the changes to disk and exit fdisk.

# Inform the operating system of partition table changes (useful after modifying partitions)
partprobe

# List all block devices and their mount points to verify the changes
lsblk

# Resize the XFS filesystem on the specified partition (/dev/sda1) to use the newly allocated space
xfs_growfs /dev/sda1
```
Option 2: Resize by Adding a New Disk
```bash
# Create a physical volume on the new disk (/dev/sda) for use with LVM
pvcreate /dev/sda

# Display information about the volume groups, including size and available space
vgdisplay

# Extend the specified volume group (<VG Name>) to include the new physical volume (/dev/sda)
vgextend <VG Name> /dev/sda

# Resize the logical volume 'opt' within the specified volume group to use all available free space, and resize the filesystem
lvextend -r -l +100%FREE /dev/mapper/<VG Name>-opt

# Inform the operating system of partition table changes (useful after modifying partitions)
partprobe
```
#### Crontab
**Overview:** Crontab is a time-based job scheduling program in Unix-like operating systems, allowing users to automate recurring tasks. The term "crontab" combines "cron" (the daemon that executes scheduled tasks) and "tab" (short for table, as the scheduling information is organized in a tabular format).

**Usage:** Crontab is ideal for scheduling scripts, commands, or programs to run at specified intervals (e.g., daily, weekly, monthly, or specific minutes within an hour). It is particularly useful for automating repetitive tasks and maintenance activities.

**Crontab File Format:** The crontab file follows this structure:
```bash
# <Minute> <Hour> <Day of Month> <Month> <Day of Week> Command
```

**Field Breakdown:**
- **Minute:** 0-59 (when the task runs)
- **Hour:** 0-23 (when the task runs)
- **Day of Month:** 1-31 (when the task runs)
- **Month:** 1-12 or names (e.g., Jan, Feb)
- **Day of Week:** 0-7 or names (0/7 = Sunday)
- **Command:** The command or script to execute

**Scheduling a Task:** To schedule a task, add a line to your crontab file using the specified format. Fields are separated by spaces or tabs, and asterisks (*) can be used to represent any value.

**Editing Crontab:** Use the command `crontab -e` to edit the crontab file for the current user.
