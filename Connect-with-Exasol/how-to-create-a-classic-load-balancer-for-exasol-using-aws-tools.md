# How to create a classic Load Balancer for Exasol using AWS tools 
## Background

An Internet-facing load balancer has a publicly resolvable DNS name, so it can route requests from clients over the Internet to the EC2 instances that are registered with the load balancer. We use this approach make your Exasol DB connectable from the internet using a single DNS name. An alternative approach using HAproxy and Keepalived (Floating IP) is described in this [article](https://community.exasol.com/t5/connect-with-exasol/how-to-create-a-haproxy-load-balancer-with-floating-ip/ta-p/1457 "How").

Charges that may apply for the load balancer can be found here: <https://aws.amazon.com/elasticloadbalancing/classicloadbalancer/pricing>.

When your load balancer is created, it receives a public DNS name that clients can use to send requests. The DNS servers resolve the DNS name of your load balancer to the public IP addresses of the load balancer nodes for your load balancer. Each load balancer node is connected to the back-end instances using private IP addresses.

In this how to we're using a simple 2+1 cluster in a private subnet (2 active node + 1 spare node). As this how to makes the database connectable from the internet, we recommend to enforce protocol encryption for all database connections (Database parameter "-forceProtocolEncryption=1").

EXA <-> EXA export and import is not supported.


## How to create a classic Load Balancer for Exasol using AWS tools

### 1. Go to the EC2 console>Load Balancing>Load Balancers

### 2. Click on "Create Load Balancer"

### 3. Choose "Classic Load Balancer", click "Continue"

### 4. Choose a Load Balancer Name, this name will also be used in the public DNS name

1. Choose the corresponding EXASOL VPC
2. Load Balancer Protocol: **TCP**
3. Load Balancer Port: **8563** (TCP Port for the clients to connect)
4. Instance Protocol: **TCP**
5. Instance Port: **8563** (EXASOL DB Port)
6. Add EXASOL Subnet
7. Click "Next"

### 5. Assign or Create a Security Group

### 6. Allow Incoming Traffic on the Listener Port

### 7. Click "Next" to configure the instances Health Check

1. Ping Protocol: **TCP**- (This does not check if the database is connectable, please use the XML-RPC interface for this task. If there is a reserve node, then this check will show the reserve node as "unhealthy"; this is normal behavior)
2. Port: 8563
3. Click "Next"

### 8. Add Exasol DB instances

1. Select **All** database nodes (active + spare)
2. Disable Cross-Zone Load Balancing and Connection Draining
3. Click "Next"

### 9. Add Tags (optional)

### 10. Review and Create Classic Load Balancer (it will take some time for DNS entries to be propagated)



