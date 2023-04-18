# GCP Remote Support VPN 
## Background

For certain Support Packages, such as [Monitoring](https://www.exasol.com/product-overview/customer-support/), Exasol will need VPN Access to the cluster to provide these services. 

## Prerequisites

To complete these steps, you will need access to GCP and have the permissions to do these actions 

## How to create the VPN

## Step 1: Create Virtual Private Gateway and VPN Tunnel

* Go to the **GCP Console**
* Open **Hybrid Connectivity** page
* Click **Create VPN Connection**
* Choose **Classic VPN and Continue**

## Step 2: Create a Google Compute Engine VPN gateway

* Type your preferred name (for example, Exasol-VPN)
* Add description (optional)
* Choose the network which you are using for Exasol cluster
* Choose a region (We recommend to choose the same region as your compute engines)
* Choose a public static IP address (if you don't have reserve new one)

## Step 3: Choose your Tunnel settings

* Type your preferred name for the tunnel
* Add description (optional)
* Add Remote peer IP address (for Exasol, the IP address is **62.128.13.20)**
* Choose the IKE version. (For exasol the requirement is **IKEv1**)
* Add IKE pre-shared key. Enter your own key or generate one automatically. Please note the key, it is not possible to get it after creating the tunnel
* Choose **Route-based** from **Routing options**
* Add Remote network IP ranges (Exasol provides the IP address. e.g. **10.60.2.0/24**)
* Click **Done** and **Create**

**Please share the IKE pre-shared key and IP address of your cloud VPN gateway with Exasol in order to create a tunnel.**

## Additional References

* [Overview of Professional Services](https://www.exasol.com/product-overview/customer-support/)
