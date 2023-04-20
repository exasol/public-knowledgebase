# Supported VPC Subnets for Clusters on AWS 
## Background

With versions prior to 5.0.15, EXASOL cluster deployments only supported CIDR block 27.1.0.0/16 and subnet 27.1.0.0/16, now it's possible to use custom CIDR blocks but with some restrictions, because the CIDR block will automatically be managed by our cluster operating system.

1. VPC CIDR block netmask must be between /16 (255.255.0.0) and /24 (255.255.255.0)
2. The first ten IP addresses of the cluster's subnet are reserved and cannot be used

## Explanation

### Getting the right VPC / subnet configuration:

The subnet used for installation of the EXASOL cluster is calculated according to the VPC CIDR range:

**1. For VPCs with 16 to 23 Bit netmasks, the subnet will have a 24 Bit mask. For a 24 Bit VPC, the subnet will have 26 Bit range.**



|  |  |  |
| --- | --- | --- |
| **VPC CIDR RANGE** | **->** | **Subnet mask** |
| 192.168.20.0/16 | -> | .../24 |
| 192.168.20.0/17 | -> | .../24 |
| ... | -> | .../24 |
| 192.168.20.0/22 | -> | .../24 |
| 192.168.20.0/23 |    | FORBIDDEN |
| 192.168.20.0/24 | -> | .../26 |
| 192.168.20.0/25 |    | FORBIDDEN |

**2. For the EXASOL subnet, the VPS's *second* available subnet is automatically used.**  
Helpful is the tool sipcalc ([http://sipcalc.tools.uebi.net/](http://sipcalc.tools.uebi.net/ "Follow")), e.g.

**Example 1:**  
The VPC is 192.168.20.0/22 (255.255.252.0) -> A .../24 subnet is used (255.255.255.0).  
`sipcalc 192.168.20.0/**24**' calculates a *network range* of 192.168.20.0 - 192.168.20.255 which is the VPC's **first** subnet.  
=> EXASOL uses the **subsequent** subnet, which is 192.168.**21**.0/24

**Example 2:**  
The VPC is 192.168.20.0/24 (255.255.255.0) -> A .../26 subnet is used (255.255.255.192).  
`sipcalc 192.168.20.0/**26**' calculates a network range of 192.168.20.0 - 192.168.20.**63** which is the VPC's first subnet.  
=> EXASOL uses the **subsequent** subnet, which is 192.168.20.**64**/26

**3. The first 10 IP addresses of the subnet are reserved.**

The license server, therefore, gets the subnet base + 10, the other nodes follow.

**This table shows some example configurations:**



|  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- |
| **VPC CIDR block** | **Public Subnet** | **Gateway** | **License Server IP address** | **IPMI network host addresses** | **First additional VLAN address** |
| 10.0.0.0/16 | 10.0.1.0/24 | 10.0.1.1 | 10.0.1.10 | 10.0.128.0 | 10.0.65.0/16 |
| 192.168.0.0/24 | 192.168.1.0/24 | 192.168.1.1 | 192.168.1.10 | 192.168.1.128 | 192.168.64.0/24 |
| 192.168.128.0/24 | 192.168.129.0/24 | 192.168.128.1 | 192.168.129.10 | 192.168.129.128 | 192.168.32.0/24 |
| 192.168.20.0/22 | 192.168.21.0/24 | 192.168.21.1 | 192.168.21.10 | 192.168.21.128 | 
| 192.168.16.0/24 | 192.168.16.64/26 | 192.168.16.65 | 192.168.16.74 | 192.168.16.96 | 192.168.128.0/26 |

## Additional References

<https://docs.exasol.com/administration/aws.htm>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 