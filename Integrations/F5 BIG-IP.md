**How to send logs via High Speed Logging to Splunk**

(a) Create a pool of remote log servers to which the BIG-IP system can send log messages
 
1. Log in to the Configuration utility.
2. Navigate to **Local Traffic** > **Pools**
3. Click **Create**.
4. In the **Name** field, type a unique name for the pool.
5. Using the **New Members** setting, add the IP address for each remote logging server that you want to include in the pool:
6. Type an IP address in the **Address** field, or select a node address from the **Node List**.
7. Type a service number in the Service Port field, or select a service name from the list.
_Note: Typical remote logging servers require port 514._
8. Click **Add**
9. Click **Finished**.


(b) Create a remote high-speed log destination
1. Navigate to **System** > **Logs** > **Configuration** > **Log Destinations** .
2. Click **Create**.
3. In the **Name** field, type a unique, identifiable name for this destination.
4. From the **Type** list, select **Remote High-Speed Log**.
_Note: Since we will be sending the logs to Splunk which require data be sent to the Splunk server in a specific format, you must create an additional log destination of the required type, and associate it with a log destination of the **Remote High-Speed Log type**. With this configuration, the BIG-IP system can send data to the servers in the required format._
5. From the **Pool Name** list, select the pool of remote log servers to which you want the BIG-IP system to send log messages.
6. From the **Protocol** list, select the protocol used by the high-speed logging pool members.
7. Click **Finished**.
_Note: With this configuration, BIG-IP system is configured to send an unformatted string of text to the log servers._

  
(c) Create a formatted remote high-speed log destination for Splunk
1. Navigate to **System** > **Logs** > **Configuration** > **Log Destinations** .
2. Click **Create**.
3. In the **Name** field, type a unique, identifiable name for this destination.
4. From the **Type** list, select **Splunk**.
5. From the **Forward To** list, select remote high-speed log destination to which you want the BIG-IP system to send log messages.
6. Click **Finished**.
 

(d) Create a Publisher
1. Navigate to **System** > **Logs** > **Configuration** > **Log Publishers** .
2. Click **Create**.
3. In the **Name** field, type a unique, identifiable name for this publisher.
4. For the **Destinations** setting, select the Splunk destination from the **Available** list, and click << to move the destination to the **Selected** list..
5. Click **Finished**.

 

(e) Creating a logging filter
1. Navigate to **System** > **Logs** > **Configuration** > **Log Filters**
2. In the **Name** field, type a unique, identifiable name for this filter.
3. From the **Severity** list, select the level of alerts that you want the system to use for this filter.
4. From the **Source** list, select the system processes from which messages will be sent to the log.
5. In the **Message ID** field, type the first eight hex-digits of the specific message ID that you want the system to include in the log. Use this field when you want a log to contain only each instance of one specific log message.
6. From the **Log Publisher** list, select the publisher that includes the destinations to which you want to send log messages.
7. Click **Finished**
