Indexer cluster deployment overview
-----------------------------------
Index replication offers benefits such as `data availability`, `data fidelity`, `data recovery`, `disaster recovery`, and `search affinity`. It ensures that an indexer is always available to handle data, and the indexed data is searchable. It also guarantees `data consistency` and `fault tolerance`.

An indexer cluster consists of:
1. A single `manager node` to manage the cluster.
2. Several to many `peer nodes` to index data and maintain multiple copies, providing redundancy and data availability.
3. One or more `search heads` to coordinate searches across the set of peer nodes and provide a unified search experience

Here is a diagram of a basic, `single-site indexer cluster`, containing three peer nodes and supporting a replication factor of 3:
<div align="center">
<img src="https://github.com/MrM8BRH/Splunk/assets/34133187/8f0eebaf-6daa-439a-a637-d37f7b4c462c">
</div>

## Deploy a cluster
   Configure the manager node with the CLI
   ```
   /opt/splunk/bin/splunk edit cluster-config -mode manager -replication_factor 4 -search_factor 3 -secret your_key -cluster_label cluster1
   /opt/splunk/bin/splunk restart
   ```
   Configure a peer node with the CLI
   ```
   /opt/splunk/bin/splunk edit cluster-config -mode slave -master_uri https://<master-ip>:8089 -secret your_key -replication_port 9100
   /opt/splunk/bin/splunk restart
   ```

   Verifying the cluster configuration using the CLI
   ```
   /opt/splunk/bin/splunk list cluster-config
   /opt/splunk/bin/splunk list cluster-peers
   /opt/splunk/bin/splunk show cluster-status
   ```

   Configure the search head with the CLI
   ```
   /opt/splunk/bin/splunk edit cluster-config -mode searchhead -master_uri https://<master-ip>:8089 -secret your_key
   /opt/splunk/bin/splunk restart
   ```
   
   All cluster configuration data is stored in `server.conf`
   ```
   /opt/splunk/etc/system/local/server.conf
   ```
   
   Maintenance mode enabled/disabled on master node.
   ```
   /opt/splunk/bin/splunk enable maintenance-mode
   /opt/splunk/bin/splunk show maintenance-mode
   /opt/splunk/bin/splunk disable maintenance-mode
   ```

   Restarting Indexer Cluster Components:
   - Restart the master node using `/opt/splunk/bin/splunk restart`
   - Restart the search head using `/opt/splunk/bin/splunk restart`
   - Perform a rolling restart of peer nodes:
      ```
      /opt/splunk/bin/splunk edit cluster-config -percent_peers_to_restart 20
      /opt/splunk/bin/splunk rolling-restart cluster-peers
      /opt/splunk/bin/splunk rolling-restart cluster-peers -searchable true
      ```
   Indexer Discovery
   
   Capability of indexer clusters that enables forwarders to connect dynamically to the full set of available peer nodes.
   
   How?
   1. Peer nodes provide their receiving ports to the master.
   2. Forwarders poll the master for the list of available peer nodes.
   3. Master transmits the peer nodes list to the forwarders.
   4. The forwarders send data to the peer nodes using load balancing.
   
   Indexer Discovery Configuration
   Master Node (Edit server.conf)
   ```
   [indexer_discovery]
   pass4SymmKey = <IDSecret>
   polling_rate = <1-10>
   ```
   
   Forwarders (Edit outputs.conf)
   ```
   [tcpout:<group_name>]
   indexerDiscovery = <ID_name>
   useACK = true
   autoLBFrequency = 120
   
   [indexer_discovery]
   master_uri = https://<ip>:8089
   pass4SymmKey = <IDSecret>
   ```
   Indexer Cluster Upgrade Considerations:
   1. Peer nodes must have the same OS family.
   2. Peer nodes must run exactly the same Splunk version.
   3. Master node must run the highest Splunk version.
   4. Search head must run higher Splunk version than the peer nodes.

   Indexer Cluster Upgrade High-level Overview:
   1. Upgrade the master node.
   2. Upgrade the search heads.
   3. Enable maintenance mode.
   4. Upgrade the peer nodes.
   5. Disable maintenance mode.

   Remove Excess Buckets
   - Using the master dashboard (GUI)
   - Using the CLI:
      ```
      /opt/splunk/bin/splunk list excess-buckets [index-name]
      /opt/splunk/bin/splunk remoev excess-buckets [index-name]
      ```
   List of commands and parameters related to clustering
   ```
   /opt/splunk/bin/splunk help clustering
   ```

---


**Best practice**: Forward manager node data to the indexer layer

Ensure necessary indexes exist on the indexers:
- Check if indexes like _audit and _internal are present on both the manager node and the indexers.
- If custom indexes exist only on the manager node, make sure to create the same indexes on the indexers to hold the corresponding manager data.

Configure the `manager node` as a _forwarder_:
- Create an outputs.conf file on the manager node.
- Configure load-balanced forwarding across the set of peer nodes.
- Turn off indexing on the manager node to prevent it from retaining data locally and forwarding it to the peers.

Note: _Ensure that the manager node is also set up as a search head in the indexer cluster. This allows it to perform searches and access the data it forwards to the peers._

Here is an example `outputs.conf` file:
```
# Turn off indexing on the manager node
[indexAndForward]
index = false
 
[tcpout]
defaultGroup = my_peers_nodes 
forwardedindex.filter.disable = true  
indexAndForward = false 
 
[tcpout:my_peers_nodes]
server=10.10.10.1:9997,10.10.10.2:9997,10.10.10.3:9997
```
_This example assumes that each peer node's receiving port is set to 9997._

Configure the peers for index replication:
- Ensure that all necessary indexes are available on the peers.
- If you need to install apps or change configurations, apply the changes to all peers in a consistent manner, ensuring that they use a common set of indexes.
- If you need to add indexes (including indexes defined by an app), configure the peers to use the same set of indexes.

Note: _After configuring the peers, you can start replicating data between the manager node and the peers._

Forwarder Outputs Example
```
[tcpout:my_peers_nodes]
useACK = true
server=10.10.10.1:9997,10.10.10.2:9997,10.10.10.3:9997
autoLBFrequency = 60
autoLBVolume = 1048576
```

Resources
---------
- [Indexer cluster deployment overview](https://docs.splunk.com/Documentation/Splunk/latest/Indexer/Clusterdeploymentoverview)
- [Deploy a search head cluster](https://docs.splunk.com/Documentation/Splunk/latest/DistSearch/SHCdeploymentoverview)
- [High availability deployment: Indexer cluster](https://docs.splunk.com/Documentation/Splunk/latest/Deploy/Indexercluster)
- [Where to create an index in a clustered environment?](https://community.splunk.com/t5/Getting-Data-In/Where-to-create-an-index-in-a-clustered-environment/m-p/425263)
- [What are some best practices for deploying new Splunk cluster step-by-step?](https://community.splunk.com/t5/Deployment-Architecture/What-are-some-best-practices-for-deploying-new-Splunk-cluster/m-p/590481)
- [High Availablity Implementation-Cluster](https://community.splunk.com/t5/Deployment-Architecture/High-Availablity-Implementation-Cluster/m-p/672656)
- [Configure the peer indexes in an indexer cluster](https://docs.splunk.com/Documentation/Splunk/latest/Indexer/Configurethepeerindexes)
- [Peer node configuration overview](https://docs.splunk.com/Documentation/Splunk/latest/Indexer/Configurethepeers)
- [Migrate non-clustered indexers to a clustered environment](https://docs.splunk.com/Documentation/Splunk/latest/Indexer/Migratenon-clusteredindexerstoaclusteredenvironment)
- [Perform a rolling upgrade of an indexer cluster](https://docs.splunk.com/Documentation/Splunk/latest/Indexer/Searchablerollingupgrade)
