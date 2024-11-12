# Exasol Monitoring Service FAQ

## Background

Exasol's Monitoring Service is a platform hosted and managed by Exasol which allows us to receive data about the performance and stability of your databases. This data is then used to provide better and faster support. For customers with Platinum Support, connection to the Monitoring Service is required for 24/7 alerting and incident management.

Connection to the Monitoring Service gives you the following benefits:
1. Faster problem identification as support is able to view a subset of logs before they are sent to Exasol
2. Better performance analysis by Exasol experts using pre-defined Grafana dashboards based on best practices
3. A quarterly Usage Report as a PDF with an insight into your database usage and any potential findings that require action.
4. (Platinum Support) 24/7 Monitoring, Alerting, and Incident Management

## How does it work

The Monitoring Service is a generic implementation using open source tools. On each node, Exasol Support installs monitoring agents which then collect relevant monitoring information from the system and the database. The Agent then sends the information to Exasol's central harvester and transforms and saves the data. Exasol Support has access to a variety of Grafana dashboards which are built on top of this information for speedy troubleshooting and incident alerting. The monitoring stack includes the following features:

- no single point of failure
- easy and secure connectivity
- fast deployment
- scalable architecture
- modern stack

## How do I get connected to the Monitoring Service
If you are interested in getting connected to the Monitoring Service, just [open a case](https://exasol.my.site.com/s/create-new-case?language=en_US) with us expressing your interest. During the processing of the case, you will need to work with your internal teams to allow your Exasol clusters to connect to Exasol's host harvester.exasol.com via the following public data gateway ports (TCP):
   - 9092
   - 10016
   - 10019
   
All nodes must be able to resolve the hostname **harvester.exasol.com**.
<br /><br />
After the internet access is available, Exasol Support will set up a meeting with you to install and configure the agents if there is no VPN already configured. Installing the agents does NOT require a downtime.

## What are the monitoring agents?

The monitoring agents are created using [Open Source Telegraf Server Agent](https://github.com/influxdata/telegraf). Updates are provided on a regular basis and can be applied by our support staff.

## How will the Monitoring Service be installed on my Exasol environment?

Exasol will install the monitoring agents on your clusters. These agents require root access and run inside the Exasol cluster process namespace.

The Exasol cluster where the monitoring agents are installed must have access to Exasol's Data Gateway via the Internet. All data sent by the agents is encrypted.

## What data is collected?

The following information is collected:

**Note: Exasol does not collect any personal data or have access to user schemas.**

- Exasol database statistics  
  - Schema "EXA_STATISTICS"
    - Sessions (every 1 minute)
    - Stats (every 30 minutes)
- Exasol cluster states (every 4 minutes)
  - DB states + DB names
  - Volume states + names  
  - Node states + names
  - HDD states + names
  - Backup states + IDs
- OS metrics  (every 1 minute)
  - Hardware metrics/events  
  - Disk metrics  
  - CPU metrics  
  - Memory metrics  
  - System load  
  - Network metrics  
  - Network connection states  
  - Swap usage  
  - DELL iDRAC 7/8/9 logs (DELL OMSA required)
- Rsyslog (log stream)
  - Exasol logs  

## How is data transferred?

Once data is collected by the nodes inside the cluster, it is converted into the Influx line protocol and shipped to our Data Gateway (harvester.exasol.com). The connection uses SASL over SSL. Data will be sent to the monitoring stack via the Internet.

Encrypted data is sent using three ports:

- A port for the metrics harvester.exasol.com:9092 (plus data ports 10016 and 10019)

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
* Agent certificate lifetime 356 days, will be renewed with each new agent release

On top of that each Exasol cluster is using a unique user + password combination in order to authenticate at harvester.exasol.com only if certificates + user + password do match monitoring data will flow into our monitoring platform.

### SOCKS5 Proxy support

If direct internet access for the monitoring agents is not allowed, data can be transferred through a [SOCKS5 proxy](https://en.wikipedia.org/wiki/SOCKS#SOCKS5). The SOCKS5 proxy must be able to resolve harvester.exasol.com and to access the TCP ports listed below. The monitoring agents installed on the Exasol hosts will then send their sensor data to one single port on the SOCKS5 proxy.

The agent only supports SOCKS5, no other SOCKS protocols are supported.

## How is data stored?

Data is stored at Exasol on an on-premise system. The data itself is unencrypted but the underlying hard disks are encrypted.

## Will I get access to the Grafana dashboards?
Currently, access to the data and the dashboards is limited to Exasol Support. We are evaluating if and how to make this available directly to customers. Each customer will receive a quarterly Usage Report with screenshots from the dashboards and key findings on performance and usage trends.



## Additional References

[Exasol On-premise](https://docs.exasol.com/db/latest/get_started/on-premise/exasol_on-premises.htm)

[Exasol Cluster Nodes](https://docs.exasol.com/db/latest/administration/on-premise/architecture/cluster_nodes.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
