## DOCS
[How to prepare TLS certificates for use with the Splunk platform](https://docs.splunk.com/Documentation/Splunk/latest/Security/HowtoprepareyoursignedcertificatesforSplunk)

[Configure Splunk indexing and forwarding to use TLS certificates](https://docs.splunk.com/Documentation/Splunk/9.1.0/Security/ConfigureSplunkforwardingtousesignedcertificates)

[Configure TLS certificates for inter-Splunk communication](https://docs.splunk.com/Documentation/Splunk/9.1.0/Security/ConfigTLSCertsS2S)

[Configure Splunk Web to use TLS certificates](https://docs.splunk.com/Documentation/Splunk/9.1.0/Security/SecureSplunkWebusingasignedcertificate)

[Test and troubleshoot TLS connections](https://docs.splunk.com/Documentation/Splunk/9.1.0/Security/Validateyourconfiguration)

## Default certificate renewal
### WEB
```
# export LD_LIBRARY_PATH=/opt/splunk/lib/:$LD_LIBRARY_PATH
mkdir /opt/splunk/etc/auth/mycerts
cd /opt/splunk/etc/auth/mycerts

/opt/splunk/bin/openssl genrsa -aes256 -out myServerPrivateKey.key 2048
/opt/splunk/bin/openssl req -new -key myServerPrivateKey.key -out myServerCertificate.csr
/opt/splunk/bin/openssl x509 -req -in myServerCertificate.csr -sha512 -signkey myServerPrivateKey.key -CAcreateserial -out myServerCertificate.pem -days 3650
chown -R splunk:splunk /opt/splunk
```

nano /opt/splunk/etc/system/local/web.conf
```
[settings]
enableSplunkWebSSL = true
privKeyPath = /opt/splunk/etc/auth/mycerts/myServerPrivateKey.key
serverCert = /opt/splunk/etc/auth/mycerts/myServerCertificate.pem
sslPassword = password
```

### SERVER
```
mv /opt/splunk/etc/auth/server.pem /opt/splunk/etc/auth/server.pem.bkp
chown -R splunk:splunk /opt/splunk
/opt/splunk/bin/splunk restart
openssl x509 -in server.pem -text
```
[Link](https://community.splunk.com/t5/Security/How-can-we-renew-this-certificate-with-a-third-party-signed/td-p/327920)

### OpenCTI
```
cp ca.pem /opt/splunk/etc/auth/opencti_ca.pem
chmod 644 /opt/splunk/etc/auth/opencti_ca.pem

nano /opt/splunk/etc/system/local/server.conf
[sslConfig]
sslRootCAPath = /opt/splunk/etc/auth/opencti_ca.pem

/opt/splunk/bin/splunk restart
/opt/splunk/bin/splunk show kvstore-status
chown -R splunk:splunk /root/.splunk/
```
