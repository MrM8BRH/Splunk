# Integration Netflow with Splunk

## Kernel Settings

Default Linux kernel settings may not be sufficient for high-volume packet capture, leading to potential data loss. To address this, update the kernel settings in your `/etc/sysctl.conf` file:

```bash
nano /etc/sysctl.conf
```
```
# Increase kernel buffer sizes for reliable packet capture
net.core.rmem_default = 33554432
net.core.rmem_max = 33554432
net.core.netdev_max_backlog = 10000
```
Reload the settings:
```
/sbin/sysctl -p
```
## Prerequisites
1. Install Go: https://go.dev/doc/install

2. Create Index, Sourcetype, File

- (Index)
Settings → Indexes → New Index:
      Index Name: `stream`

- (Sourcetype)
Settings → Source types → New Source Type:

  Name: `stream:netflow`

  Category: `Network & Security`

  Indexed extractions: `json`
- (File)
```
touch /var/log/netflow
```
4. Install goflow:
```
dnf install git
git clone https://github.com/cloudflare/goflow
cd goflow/cmd/goflow
go build
```

Netflow V9
```
./goflow -kafka=false -sflow=false -nfl=false -logfmt=json -nf.addr=<IP Addr> -nf.port=2055 -workers=3 -message.fields="Type,TimeReceived,SequenceNum,TimeFlowStart,TimeFlowEnd,Bytes,Packets,SrcAddr,DstAddr,Proto,SrcPort,DstPort,InIf,OutIf,SrcMac,DstMac,SrcVlan,DstVlan,VlanId,TCPFlags,IcmpType,FragmentId,NextHop" >> /var/log/netflow
```

Netflow V5
```
./goflow -kafka=false -sflow=false -nf=false -logfmt=json -nfl.addr=<IP Addr> -nfl.port=9995 -workers=3 -message.fields="Type,TimeReceived,SequenceNum,TimeFlowStart,TimeFlowEnd,Bytes,Packets,SrcAddr,DstAddr,Proto,SrcPort,DstPort,InIf,OutIf,SrcMac,DstMac,SrcVlan,DstVlan,VlanId,TCPFlags,IcmpType,FragmentId,NextHop" >> /var/log/netflow
```

```diff
- Make sure to replace all occurrences of `<IP Addr>` with your specific IP address.
```

## Monitor netflow file through universal forwarder

Add the following monitor stanza to `inputs.conf`:
```
[monitor:///var/log/netflow]
disabled = false
index = stream
sourcetype = stream:netflow
```

## Cronjob for Netflow
Edit the crontab:
```
crontab -e
```
Ensure no process is using UDP port 2055, kill if found. Then, reset netflow log and start Netflow V9:
```
* * * * * netstat -tulpn | awk '$4 ~ /:2055$/ {sub(/\/.*/, "", $NF); print $NF}' | xargs -r kill -9 ; /bin/rm -f /var/log/netflow && touch /var/log/netflow ; (cd /root/goflow/cmd/goflow && ./goflow -kafka=false -sflow=false -nfl=false -logfmt=json -nf.addr=<IP Addr> -nf.port=2055 -workers=3 -message.fields="Type,TimeReceived,SequenceNum,TimeFlowStart,TimeFlowEnd,Bytes,Packets,SrcAddr,DstAddr,Proto,SrcPort,DstPort,InIf,OutIf,SrcMac,DstMac,SrcVlan,DstVlan,VlanId,TCPFlags,IcmpType,FragmentId,NextHop" >> /var/log/netflow)
```
Ensure no process is using UDP port 9995, kill if found. Then, reset netflow log and start Netflow V5:
```
* * * * * netstat -tulpn | awk '$4 ~ /:9995$/ {sub(/\/.*/, "", $NF); print $NF}' | xargs -r kill -9 ; /bin/rm -f /var/log/netflow && touch /var/log/netflow ; (cd /root/goflow/cmd/goflow && ./goflow -kafka=false -sflow=false -nf=false -logfmt=json -nfl.addr=<IP Addr> -nfl.port=9995 -workers=3 -message.fields="Type,TimeReceived,SequenceNum,TimeFlowStart,TimeFlowEnd,Bytes,Packets,SrcAddr,DstAddr,Proto,SrcPort,DstPort,InIf,OutIf,SrcMac,DstMac,SrcVlan,DstVlan,VlanId,TCPFlags,IcmpType,FragmentId,NextHop" >> /var/log/netflow)
```
