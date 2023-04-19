# Network Requirements for Hadoop Connectivity 
## Background

Hadoop ETL UDFs are the main way to load data from Hadoop into Exasol (HCatalog tables on HDFS). In order to deploy the ETL UDFs, you need to set up the connectivity between Exasol and Hadoop. This article describes the network requirements to do this.

For a full description of using Hadoop ETL UDFs, refer to the Hadoop ETL UDFs document on github: <https://github.com/EXASOL/hadoop-etl-udfs/blob/master/README.md>

## Connectivity Requirements

* All Exasol nodes need access to either the Hive Metastore (recommended) or to WebHCatalog:
	+ The **Hive Metastore** typically runs on port **9083** of the Hive Metastore server (hive.metastore.uris property in Hive). It uses a native Thrift API, which is faster than WebHCatalog.
	+ The **WebHCatalog server** (formerly called Templeton) typically runs on port **50111** on a specific server (templeton.port property).
* All Exasol nodes need access to the namenode and all datanodes, either via the native HDFS interface (recommended) or via the HTTP REST API (WebHDFS or HttpFS)
	+ **HDFS** (recommended): The namenode service typically runs on port 8020 (fs.defaultFS property), the datanode service on port **50010** or **1004** in Kerberos environments (dfs.datanode.address property)
	+ **WebHDFS**: The namenode service for WebHDFS typically runs on port **50070** on each namenode (dfs.namenode.http-address property), and on port **50075**(dfs.datanode.http.address property) on each datanode. If you use HTTPS, the ports are **50470** for the namenode (dfs.namenode.https-address) and **50475** for the datanode (dfs.datanode.https. address).
	+ **HttpFS**: Alternatively to WebHDFS you can use HttpFS, exposing the same REST API as WebHDFS. It typically runs on port **14000** of each namenode. The disadvantage compared to WebHDFS is that all data are streamed through a single service, whereas webHDFS redirects to the datanodes for the data transfer.

**Kerberos**: If your Hadoop uses Kerberos authentication, the UDFs will authenticate using a keytab file. Each Exasol node needs access to the Kerberos KDC (key distribution center), running on port **88**. The KDC is configured in the kerberos config file, which is used for the authentication.

