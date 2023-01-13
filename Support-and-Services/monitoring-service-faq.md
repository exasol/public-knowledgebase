# Exasol Monitoring Service FAQ

## Background

Exasol's current Monitoring Service is built on a Nagios setup based on the legacy XML-RPC API. The new Monitoring Service is a generic implementation no longer dependent on an external API. Instead, locally installed monitoring agents on each Exasol node collects relevant monitoring information.

The advantages of the new monitoring service are:

- no single point of failure
- easy and secure connectivity
- fast deployment
- scalable architecture
- modern stack
- web GUI (planned for future use)
- ready to be used with the new v8 release (ETA 2023 - Q1/Q2)

## Explanation

### What are the monitoring agents?

The monitoring agents are created using [Open Source Telegraf Server Agent](https://github.com/influxdata/telegraf). Updates are provided on a regular basis and can be applied by our support staff.

### How will the new Monitoring Service be installed on your Exasol environment?

Exasol will install the monitoring agents on your clusters. These agents require root access and run inside the Exasol cluster process namespace.

The Exasol cluster where the monitoring agents are installed must have access to Exasol's Data Gateway via the Internet. All data sent by the agents is encrypted.

### What data is collected?

The following information is collected:

**Note**: Just like our current monitoring solution, Exasol does not collect any personal data.

- Exasol database statistics  
  - Schema EXA\_STATISTICS
- Exasol cluster states  
  - DB states + DB names
  - Volume states + names  
  - Node states + names
  - HDD states + names
  - Backup states + IDs
- OS metrics  
  - Hardware metrics/events  
  - Disk metrics  
  - CPU metrics  
  - Memory metrics  
  - System load  
  - Network metrics  
  - Network connection states  
  - Swap usage  
  - DELL iDRAC 7/8/9 logs
- Rsyslog  
  - Exasol logs  

### How is data transferred?

Once data is collected by the nodes inside the cluster, it is converted into the Influx line protocol and shipped to the Data Gateway. The connection uses SASL and SSL, or SSL only for Rsyslog messages. Data will be sent to the monitoring stack via the Internet.

Encrypted data is sent using four ports:

- A port for the metrics harvester.exasol.com:9092 (plus data ports 10016 and 10019).
- A port for Rsyslog harvester.exasol.com:1514.

### How is data stored?

Data is stored at Exasol on an on-premise system. As with our current monitoring solution, the data itself is unencrypted but the underlying hard disk is encrypted.

### What’s next?

1. Existing customers need to allow their Exasol clusters to connect to Exasol's host harvester.exasol.com via four public data gateway ports (TCP):
   - 1514
   - 9092
   - 10016
   - 10019
2. Exasol will install the Monitoring Agents on the existing Exasol clusters.

The current and new monitoring solutions will run in parallel starting from 09.01.2023 - 31.03.2023. This transitional phase will be used to find and fix any issues you encounter using the new Monitoring Service. After 4 weeks the old monitoring solution will be decommissioned.

### When can it be installed?

Release date: 09.01.2023
Retire date of existing monitoring service: 31.03.2023

#### Rollout

Exasol Support will get in touch by the release date with you and plan the rollout.

#### Requirements

- Firewall settings must be adjusted so that the host harvester.exasol.com can be reached via the aforementioned ports.
- A session is scheduled to install the new monitoring agents.

## Additional References

[Exasol On-premise](https://docs.exasol.com/db/latest/get_started/on-premise/exasol_on-premises.htm)

[Exasol Cluster Nodes](https://docs.exasol.com/db/latest/administration/on-premise/architecture/cluster_nodes.htm?Highlight=clusters)
