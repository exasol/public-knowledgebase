# Firewall configuration for installing/operating a cluster 
This article describes the way a firewall should be configured in preparation for Exasol installation and then for operating the cluster.

#### Exasol installation

* ALLOW
	+ SSH access to the license node (TCP port 20 + 22)
	+ LOM access to the license node (KVM, EXASOL installation ISO mounted)
	+ LOM access to the data nodes (KVM)
	+ HTTP/S access to all cluster nodes (EXAoperation web UI ,TCP 80/443). The web UI is running as a cluster service and can be accessed from any cluster node.

#### Operating the cluster

* ALLOW
	+ Database port clients use to connect to the database (default TCP 8563)
	+ HTTP/S access to all cluster nodes (EXAoperation web UI, TCP 80/443)
	+ SSH access to all cluster members (TCP port 20 + 22)
	+ To get most out of the web UI each cluster node should be able to access the LOM of each other (ipmitool is used for providing basic hardware vitality information)
	+ NTP (TCP/UDP 123)
	+ DNS (TCP/UDP 53)
	+ optional: LDAP (TCP/UDP 389)
