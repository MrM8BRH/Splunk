## DOCS
[How to prepare TLS certificates for use with the Splunk platform](https://docs.splunk.com/Documentation/Splunk/latest/Security/HowtoprepareyoursignedcertificatesforSplunk)

[Configure Splunk indexing and forwarding to use TLS certificates](https://docs.splunk.com/Documentation/Splunk/9.1.0/Security/ConfigureSplunkforwardingtousesignedcertificates)

[Configure TLS certificates for inter-Splunk communication](https://docs.splunk.com/Documentation/Splunk/9.1.0/Security/ConfigTLSCertsS2S)

[Configure Splunk Web to use TLS certificates](https://docs.splunk.com/Documentation/Splunk/9.1.0/Security/SecureSplunkWebusingasignedcertificate)

[Test and troubleshoot TLS connections](https://docs.splunk.com/Documentation/Splunk/9.1.0/Security/Validateyourconfiguration)

## SSL Configuration
[web.conf](https://docs.splunk.com/Documentation/Splunk/latest/admin/webconf)
```
[settings]
enableSplunkWebSSL = true
privKeyPath = /opt/splunk/etc/auth/mycerts/myCertAuthPrivateKey.key
serverCert = /opt/splunk/etc/auth/mycerts/myServerCertificate.pem
sslPassword = password
```

## Default certificate renewal
[Link](https://docs.splunk.com/Documentation/Splunk/9.2.0/Security/Howtoself-signcertificates)
```
# (1)
export SPLUNK_HOME=/opt/splunk/
mkdir $SPLUNK_HOME/etc/auth/mycerts
cd $SPLUNK_HOME/etc/auth/mycerts
openssl genrsa -aes256 -out myCertAuthPrivateKey.key 2048
openssl req -new -key myCertAuthPrivateKey.key -out myCertAuthCertificate.csr
openssl x509 -req -in myCertAuthCertificate.csr -sha512 -signkey myCertAuthPrivateKey.key -CAcreateserial -out myCertAuthCertificate.pem -days 1095
# (2)
touch myServerCertificate myServerCertificate.pem
chmod 755 *
openssl req -new -key myServerPrivateKey.key -out myServerCertificate.csr
openssl x509 -req -in myServerCertificate.csr -SHA256 -CA myCertAuthCertificate.pem -CAkey myCertAuthPrivateKey.key -CAcreateserial -out myServerCertificate.pem -days 1095
```

[Link](https://community.splunk.com/t5/Security/How-can-we-renew-this-certificate-with-a-third-party-signed/td-p/327920)
```
export LD_LIBRARY_PATH=/opt/splunk/lib/:$LD_LIBRARY_PATH
/opt/splunk/bin/splunk createssl server-cert -d /opt/splunk/etc/auth -n SplunkServerDefaultCert
cd /opt/splunk/etc/auth
mv server.pem server.pem.orig
mv SplunkServerDefaultCert.pem server.pem
openssl x509 -in server.pem -text
```


## Split a .pfx File into .pem and .key Files Using OpenSSL
The following command will generate a private key file without a password from your .pfx file (requires password):

`openssl pkcs12 -in certificate.pfx -out privateKey.key -nocerts -nodes`

The following command will generate a .pem certificate file from your .pfx file which will include any intermediate and root certificates that may be included in the .pfx file. (requires password):

`openssl pkcs12 -in certificate.pfx -out certificate.pem -nokeys -clcerts`

`/opt/splunk/etc/auth`
