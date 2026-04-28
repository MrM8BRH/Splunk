## Splunk Default Certificate Renewal
### Web Certificate (Splunk Web SSL)
```
# Prepare certificate directory
mkdir /opt/splunk/etc/auth/mycerts
cd /opt/splunk/etc/auth/mycerts

# Generate private key
/opt/splunk/bin/openssl genrsa -aes256 -out myServerPrivateKey.key 2048

# Generate CSR (Certificate Signing Request)
/opt/splunk/bin/openssl req -new -key myServerPrivateKey.key -out myServerCertificate.csr

# Generate self-signed certificate
/opt/splunk/bin/openssl x509 -req -in myServerCertificate.csr -sha512 -signkey myServerPrivateKey.key -CAcreateserial -out myServerCertificate.pem -days 3650

# Fix ownership
chown -R splunk:splunk /opt/splunk
```
**Configure Splunk Web SSL**

nano /opt/splunk/etc/system/local/web.conf
```
[settings]
enableSplunkWebSSL = true
privKeyPath = /opt/splunk/etc/auth/mycerts/myServerPrivateKey.key
serverCert = /opt/splunk/etc/auth/mycerts/myServerCertificate.pem
sslPassword = password
```

### Splunk Server Certificate (server.pem)
```
# Backup existing certificate
mv /opt/splunk/etc/auth/server.pem /opt/splunk/etc/auth/server.pem.bkp

# Ensure permissions
chown -R splunk:splunk /opt/splunk

# Restart Splunk
/opt/splunk/bin/splunk restart

# Verify certificate
openssl x509 -in server.pem -text
```
[How can we renew this certificate with a third-party signed certificate?](https://community.splunk.com/t5/Security/How-can-we-renew-this-certificate-with-a-third-party-signed/td-p/327920)


## Resources
- [Introduction to securing the Splunk platform with TLS](https://help.splunk.com/en/splunk-enterprise/administer/manage-users-and-security/10.2/secure-splunk-platform-communications-with-transport-layer-security-certificates/introduction-to-securing-the-splunk-platform-with-tls)
- [Test and troubleshoot TLS connections](https://help.splunk.com/en/splunk-enterprise/administer/manage-users-and-security/10.2/secure-splunk-platform-communications-with-transport-layer-security-certificates/test-and-troubleshoot-tls-connections)
