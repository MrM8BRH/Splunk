# JAVA for DB Connect app
Linux x64 Compressed Archive
- [v21](https://www.oracle.com/java/technologies/javase/jdk21-archive-downloads.html) # Recommended
- [v17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html)

```
tar -xzvf jdk-<version>_linux-x64_bin.tar.gz -C /opt/splunk/etc/apps/splunk_app_db_connect/linux_x86

chown -R splunk:splunk /opt/splunk
```

Path: /opt/splunk/etc/apps/splunk_app_db_connect/linux_x86/jdk-<version>/

```
/opt/splunk/bin/splunk restart
```
