# AWS Remote support VPN 
## Background

For certain Support Packages, such as [Monitoring](https://www.exasol.com/product-overview/customer-support/), Exasol will need VPN Access to the cluster to provide these services. 

## Prerequisites

To complete these steps, you will need access to AWS and have the permissions to do these actions

## How to create a VPN between AWS and Exasol Support

## Step 1: Create Virtual Private Gateway

* Go to the **Amazon VPC dashboard**
* In VPN Connections group, click **Virtual Private Gateways**
* Click Create virtual private gateway
* Type your preferred name (for example, test-vpn)
* ASN: Amazon default ASN
* Click **create Virtual Private Gateway**

Attach your VPC to your virtual private gateway:

* Select virtual private gateway and from the actions menu click "Attach to VPC". Select VPC that you want to attach. You can attach your VPC only to one virtual private gateway.

## Step 2: Create Customer Gateway

In the VPN Connections group, click Customer Gateways

* Click **Create Customer Gateway**
* Type your preferred name
* Select **static routing**
* Select the IP address of your gateway. Exasol gateway IP: 62.128.13.20 and click create customer gateway

## Step 3: Create a VPN Connection

* In VPN Connections group, click **VPN Connections**  
Click **Create VPN Connection**
* Type your preferred name
* Select Virtual Private Gateway which was created in **step 1**
* Select Customer Gateway which was created in **step 2**
* Select static routing and **type IP range of company (Exasol range e.g. : 10.60.2.0/24) and click Create VPN connection**
* Select VPN connection and click Download Configuration.
* Select "Generic" and click Download. Provide configuration to the responsible person for the VPN in the company

## Step 4: Check Routing Table of your VPC (or subnet)

* Allow traffic from new IP range which was added via VPN. In routing table, one needs to enable route propagation for virtual private gateway

## Additional References

* [Overview of Professional Services](https://www.exasol.com/product-overview/customer-support/)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 