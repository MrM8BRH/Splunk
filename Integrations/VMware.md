VMware Appliance Management (https://x.x.x.x:5480)

![VCSA-Management-720x450](https://github.com/user-attachments/assets/9397e990-6e2f-40c1-a012-2a3a479d4fd4)

```
esxcli system syslog config set --loghost='udp://192.168.5.118:1515'
esxcli system syslog reload
```

```
esxcli system syslog config get
esxcli network firewall ruleset list | grep syslog
```
