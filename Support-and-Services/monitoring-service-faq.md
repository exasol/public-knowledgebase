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

Encryption:

- Agents are shipped with built-in certificates in order to connect to harvester.exasol.com
- harvester.exasol.com uses official certificates signed by digicert.com (openssl s_client -servername harvester.exasol.com -connect harvester.exasol.com:443)
- The agent certificates are valid for one year from the date of the installation
- The agent certificate expiry is monitored by Exasol
- The agent certificate expiry is reset back to one year each time a new agent release is installed

Certificates:

Monitoring agent certificates used by the Exasol monitoring agents (can be downloaded from here https://letsencrypt.org/certificates/):

* https://letsencrypt.org/certs/isrgrootx1.pem
* https://letsencrypt.org/certs/lets-encrypt-r3.pem
* https://letsencrypt.org/certs/isrg-root-x1-cross-signed.pem
* https://letsencrypt.org/certs/lets-encrypt-r3-cross-signed.pem

On top of that each Exasol cluster is using a unique user + password combination in order to authenticate at harvester.exasol.com only if certificates + user + password do match monitoring data will flow into our monitoring platform.

#### SOCKS5 Proxy support

If direct internet access for the monitoring agents is not allowed data can be transferred through a SOCKS5 proxy (https://en.wikipedia.org/wiki/SOCKS#SOCKS5). The SOCKS5 proxy also needs to be able to resolve harvester.exasol.com and to access the below listed TCP ports.

### How is data stored?

Data is stored at Exasol on an on-premise system. As with our current monitoring solution, the data itself is unencrypted but the underlying hard disk is encrypted.

### What’s next?

1. Existing customers need to allow their Exasol clusters to connect to Exasol's host harvester.exasol.com via four public data gateway ports (TCP):
   - 1514
   - 9092
   - 10016
   - 10019
   
   All cluster instances must be able to resolve the hostname harvester.exasol.com.
2. Exasol will install the Monitoring Agents on the existing Exasol clusters.

    A downtime of the database is not required.

The current and new monitoring solutions will run in parallel starting from 09.01.2023 - 31.03.2023.

### When can it be installed?

Release date: 09.01.2023
Retire date of existing monitoring service: 31.03.2023

#### Rollout

Exasol Support will get in touch by the release date with you and plan the rollout.

#### Requirements

- Firewall settings must be adjusted so that the host harvester.exasol.com can be reached via the aforementioned ports.
- A session is scheduled to install the new monitoring agents if no VPN between Exasol and your environment is existing.

## Additional References

[Exasol On-premise](https://docs.exasol.com/db/latest/get_started/on-premise/exasol_on-premises.htm)

[Exasol Cluster Nodes](https://docs.exasol.com/db/latest/administration/on-premise/architecture/cluster_nodes.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
