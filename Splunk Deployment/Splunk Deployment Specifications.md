- [Reference hardware](https://docs.splunk.com/Documentation/Splunk/latest/Capacity/Referencehardware)
- [System requirements for use of Splunk Enterprise on-premises](https://docs.splunk.com/Documentation/Splunk/latest/Installation/Systemrequirements#Supported_Operating_Systems)
- [Minimum specifications for a production deployment (Splunk ES v8)](https://help.splunk.com/en/splunk-enterprise-security-8/install/8.0/planning/minimum-specifications-for-a-production-deployment)

### Distributed Deployment

#### Server Requirements

1.  Search Heads (2 instances)
2.  -   **Physical CPU Cores:** 16 || vCPU Cores: 32
    -   **RAM:** 32 GB
    -   **Storage:** 350 GB
    -   **Purpose:** SIEM (Enterprise Security Application) and application monitoring (F5, FortiGate, CrowdStrike, etc.).
3.  Deployment Server (1 instance)
4.  -   **Physical CPU Cores:** 12 || vCPU Cores: 24
    -   **RAM:** 16 GB
    -   **Storage:** 250 GB
    -   **Purpose:** Manage Splunk agents (Windows, Linux, etc.) and deploy add-ons.
5.  Indexer Server (1 instance)
6.  -   **Physical CPU Cores:** 16 || vCPU Cores: 32
    -   **RAM:** 32 GB
    -   **Storage:** 2 TB
    -   **Purpose:** Store and process large data volumes.
7.  Syslog/SC4S Server (Choose one)
    -   **Option 1:** Syslog Server
        -   **Physical CPU Cores:** 4 || vCPU Cores: 8
        -   **RAM:** 8 GB
        -   **Storage:** 400 GB
    -   **Option 2:** SC4S Server
        -   **Physical CPU Cores:** 4 || vCPU Cores: 8
        -   **RAM:** 8 GB
        -   **Storage:** 200 GB
    -   **Recommendation:** SC4S for improved scalability and performance.

#### Partitioning Guidelines

-   **Operating System:** RHEL/CentOS with Ext4 LVM partitioning.
-   **Splunk Servers:**
    -   **Root (`/`):** 15 GB
    -   **Swap:** 8 GB
    -   **`/tmp`:** 10 GB
    -   **`/var`:** 15 GB
    -   **`/boot`:** 1 GB
    -   **`/boot/efi`:** 1 GB
    -   Remaining storage allocated to **`/opt`**.
-   **Syslog Server:**
    -   **Root (`/`):** 20 GB
    -   **Swap:** 8 GB
    -   **`/tmp`:** 10 GB
    -   **`/boot`:** 1 GB
    -   **`/boot/efi`:** 1 GB
    -   **`/opt`:** 20 GB
    -   Remaining storage allocated to **`/var`**.
-   **SC4S Server:**
    -   **Root (`/`):** 20 GB
    -   **Swap:** 8 GB
    -   **`/tmp`:** 10 GB
    -   **`/boot`:** 1 GB
    -   **`/boot/efi`:** 1 GB
    -   Remaining storage allocated to **`/var`**.

* * * * *

### Single Deployment

#### Server Requirements

1.  Splunk Server (1 instance)
2.  -   **Roles:** Search, storage, agent management, and add-on deployment.
    -   **Partitioning:**
        -   **Swap:** 8 GB
        -   **`/tmp`:** 10 GB
        -   **Root (`/`):** 10 GB
        -   **`/boot`:** 1 GB
        -   **`/boot/efi`:** 1 GB
        -   Remaining storage for **`/opt`**.
3.  SC4S Server (1 instance)
4.  -   **Purpose:** Agentless data ingestion (firewalls, routers, switches, etc.).
    -   **Partitioning:**
        -   **Swap:** 8 GB
        -   **`/tmp`:** 10 GB
        -   **`/opt`:** 10 GB
        -   **`/boot`:** 1 GB
        -   **`/boot/efi`:** 1 GB
        -   Remaining storage for **`/var`**.

* * * * *

### Indexer Cluster Deployment

#### System Requirements



| System | VM Qty | RAM/vRAM | CPU/vCPU | Storage/VM | IOPS/VM | Retention Period |
|---|---|---|---|---|---|---|
| Splunk Search Head | 2 | 32 GB | 16 physical cores (or 32 vCPU) | 300 GB | 1200 | N/A |
| Splunk Indexer | 3 | 16 GB | 16 physical cores (or 32 vCPU) | 4 TB | 1200 | 1 year |
| Manager Node | 1 | 16 GB | 8 physical cores (or 12 vCPU) | 100 GB | 800 | N/A |
| Syslog-ng Server | 1 | 16 GB | 8 physical cores (or 12 vCPU) | 200 GB | 800 | 5 days |

* * * * *

### All-In-One Deployment

#### System Requirements
| System | VM Qty | RAM/vRAM | CPU/vCPU | Storage/VM | IOPS/VM | Retention Period |
|---|---|---|---|---|---|---|
| Splunk Search & Indexer | 1 | 32 GB | 16 physical cores (or 32 vCPU) | 1 TB | 1200 | N/A |
| Syslog-ng Server | 1 | 16 GB | 8 physical cores (or 12 vCPU) | 200 GB | 800 | 5 days |

* * * * *

**General Notes:**

-   **OS:** Use RHEL/CentOS (latest version) for all servers.
-   **CPU Speed:** Minimum 2 GHz/core for physical/virtual CPUs.

