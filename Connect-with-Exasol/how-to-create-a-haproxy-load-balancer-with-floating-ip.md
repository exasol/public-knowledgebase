# How to create a HAproxy Load Balancer with floating IP 
### Background

An Internet-facing load balancer has a publicly available IP Address, so it can route requests from clients over the Internet to the EC2 instances that are registered with the load balancer. We use this approach make your EXASOL DB connectable from the internet using a single static EIP.

In this how to we're using a simple 2+1 cluster in a private subnet (2 active node + 1 spare node). As this how to makes the database connectable from the internet, we recommend to enforce protocol encryption for all database connections (Database parameter "-forceProtocolEncryption=1").

EXA<->EXA export and import is not supported.

## Prerequisites

1. 2x equally equipped instances, eg. t2-micro Amazon Linux AMI (RedHat)
2. 2x Public IP addresses
3. 1x Elastic IP address
4. AWS API access (AWS Secret and AWS Key)
5. HAproxy and Keepalived

## How to create a HAproxy Load Balancer with floating IP

This How to describes the installation of two HAproxy instances (Master 10.0.1.207 and Slave 10.0.1.190, the EXASOL nodes use 10.0.1.11,10.0.1.12,10.0.1.13).

## Installation

### 1. From the EC2 console launch a t2.micro Amazon Linux instance using the EXASOL subnet

### 2. Enable Auto-assign Public IP

### 3. Add Storage and Tags according to your needs

### 4. The security Group should allow incoming traffic on the database port TCP 8563 and allow SSH for configuration and installation of the packages. If you want to use HAproxy statistics server also open TCP 9090. Master and Slave also need to exchange vitality information.

### 5. Log into both instances using SSH user ec2-user

### 6. Update system packages and install haproxy and keepalived (ensure you get the latest version of keepalived <http://www.keepalived.org/download.html>)


```
[ec2-user@ip-10-0-1-207 ~]$ sudo mkdir /usr/libexec/keepalived/
[ec2-user@ip-10-0-1-207 ~]$ sudo yum -y upgrade && sudo yum -y install haproxy keepalived && sudo reboot
```
### 7. Use the packages from the repo (Point 6) **OR** (Point 7) install the latest keepalived (additional packages are required see below)


```
[root@ip-10-0-1-207]# yum install -y openssl-devel kernel-devel kernel-headers gcc && wget http://www.keepalived.org/software/keepalived-1.3.2.tar.gz && tar xf keepalived* && cd keepalived-1.3.2 && mkdir /opt/keepalived && ./configure --prefix=/opt/keepalived && make && make install
```
Use the steps below when keepalived has been compiled from source. We also need to the init script (attached to this article) and sysconfig file of keepalived.


```
[root@ip-10-0-1-207]# cp keepalived_initd.txt /etc/init.d/keepalived
[root@ip-10-0-1-207]# cp /root/keepalived-1.3.2/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
[root@ip-10-0-1-207]# cp /root/keepalived-1.3.2/keepalived/etc/init/keepalived.conf /etc/init/
[root@ip-10-0-1-207]# ln -s /opt/keepalived/sbin/keepalived /usr/sbin/
[root@ip-10-0-1-207]# mkdir /etc/keepalived/
[root@ip-10-0-1-207]# cp /opt/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/
[root@ip-10-0-1-207]# mkdir /usr/libexec/keepalived/
[root@ip-10-0-1-207]# useradd -M keepalived_script
```
## Configuration

### 1. Configure HAproxy Master and Slave (copy it to both instances)


```
[ec2-user@ip-10-0-1-207 ~]$ cat /etc/haproxy/haproxy.cfg
global
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

defaults
        log     global
        mode    tcp
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client 50000
        timeout server 50000

listen stats :9090
        balance
        mode http
        stats enable
        stats uri /haproxy_stats
        stats auth admin:strongPassworD

listen exasol_proxy :8563
        mode tcp
        option tcplog
        balance roundrobin

        server ip-10-0-1-11.eu-west-1.compute.internal 10.0.1.11:8563 weight 1 check rise 2 fall 3
        server ip-10-0-1-12.eu-west-1.compute.internal 10.0.1.12:8563 weight 1 check rise 2 fall 3
        server ip-10-0-1-13.eu-west-1.compute.internal 10.0.1.13:8563 weight 1 check rise 2 fall 3 
```
### 2. Configure Keepalived Master


```
[ec2-user@ip-10-0-1-207 ~]$ cat /etc/keepalived/keepalived.conf
vrrp_script chk_haproxy {
script "pidof haproxy"
interval 2
}

vrrp_instance VI_1 {
debug 2
interface eth0                  # interface to monitor
state MASTER
virtual_router_id 1             # Assign one ID for this route
priority 101                    # 101 on master, 100 on slave
unicast_src_ip 10.0.1.207       # Private IP
unicast_peer {
10.0.1.190
}
track_script {
chk_haproxy
}
notify_master "/usr/libexec/keepalived/notify.sh MASTER"
notify_backup "/usr/libexec/keepalived/notify.sh BACKUP"
notify_fault "/usr/libexec/keepalived/notify.sh FAULT"  

}
```
### 3. Configure Keepalived Slave


```
[ec2-user@ip-10-0-1-190 ~]$ cat /etc/keepalived/keepalived.conf
vrrp_script chk_haproxy {
script "pidof haproxy"
interval 2
}

vrrp_instance VI_1 {
debug 2
interface eth0                  # interface to monitor
state BACKUP
virtual_router_id 1             # Assign one ID for this route
priority 100                    # 101 on master, 100 on slave
unicast_src_ip 10.0.1.190       # Private IP
unicast_peer {
10.0.1.207
}
track_script {
chk_haproxy
}
notify_master "/usr/libexec/keepalived/notify.sh MASTER"
notify_backup "/usr/libexec/keepalived/notify.sh BACKUP"
notify_fault "/usr/libexec/keepalived/notify.sh FAULT"  
}   
```
### 4. Keepalived will trigger a script when the HAproxy service fails on the current master, deploy the scripts (**notify.sh, master.sh, backup.sh**) on both instances ( (!)change owner to keepalived_script if using the latest version of keepalived)


```
[root@ip-10-0-1-207 ec2-user]# cat /usr/libexec/keepalived/notify.sh
#!/bin/bash                                                         
                                                                    
STATE=$1                                                            
NOW=$(date +"%D %T")                                                
KEEPALIVED="/tmp"                                                   
                                                                    
case $STATE in                                                      
        "MASTER") touch $KEEPALIVED/MASTER                          
                  echo "$NOW Becoming MASTER" >> $KEEPALIVED/COUNTER
                  /usr/libexec/keepalived/master.sh                 
                  exit 0                                            
                  ;;                                                
        "BACKUP") rm $KEEPALIVED/MASTER                             
                  echo "$NOW Becoming BACKUP" >> $KEEPALIVED/COUNTER
                  /usr/libexec/keepalived/backup.sh                 
                  exit 0                                            
                  ;;                                                
        "FAULT")  rm $KEEPALIVED/MASTER                             
                  echo "$NOW Becoming FAULT" >> $KEEPALIVED/COUNTER 
                  /usr/libexec/keepalived/backup.sh                  
                  exit 0                                            
                  ;;                                                
        *)        echo "unknown state"                              
                  echo "$NOW Becoming UNKOWN" >> $KEEPALIVED/COUNTER
                  exit 1                                            
                  ;;                                                
esac                                                                  
```
### 5. Master Script (change owner to keepalived_script if using the latest version of keepalived)


```
[root@ip-10-0-1-207 ec2-user]# cat /usr/libexec/keepalived/master.sh
#!/bin/bash                                                                                                            
                                                                                                                       
exec >> /tmp/master.log                                                                                                
exec 2>&1                                                                                                              
#set -x                                                                                                                 
                                                                                                                       
AWS_ACCESS_KEY=Key                                                                            
AWS_SECRET_KEY=Secret                                                         
export EC2_URL=https://ec2.eu-west-1.amazonaws.com                                                                     
export EC2_HOME="/opt/aws/apitools/ec2"                                                                                
export JAVA_HOME=/usr/lib/jvm/jre                                                                                      
export AWS_CLOUDWATCH_HOME=/opt/aws/apitools/mon                                                                       
export AWS_PATH=/opt/aws                                                                                               
export AWS_AUTO_SCALING_HOME=/opt/aws/apitools/as                                                                      
export AWS_ELB_HOME=/opt/aws/apitools/elb                                                                              
                                                                                                                       
EIP=34.249.49.35 # Elastic IP to be associated                                                                         
                                                                                                                       
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)                                             
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)                                                                                                                                                                 
/opt/aws/bin/ec2-associate-address -O $AWS_ACCESS_KEY -W $AWS_SECRET_KEY -U $EC2_URL $EIP -instance $INSTANCE_ID -p $PRIVATE_IP --allow-reassociation
echo "$(date) I'm master now"
```
### 6. Backup Script (change owner to keepalived_script if using the latest version of keepalived)


```
[root@ip-10-0-1-207 ec2-user]# cat /usr/libexec/keepalived/backup.sh
#!/bin/bash                                                                                                    
                                                                                                               
exec >> /tmp/backup.log                                                                                        
exec 2>&1                                                                                                      
#set -x                                                                                                         

echo "$(date) I'm backup nothing to do" 
```
### 7. Make keepalived scripts executable (both instances)


```
[root@ip-10-0-1-207 ec2-user]# chmod +x /usr/libexec/keepalived/*sh && chmod 700 /usr/libexec/keepalived/*sh 
```
### 8. Enable HAproxy und Keepalived on Start-up (both instances)


```
[root@ip-10-0-1-207 ec2-user]# chkconfig haproxy on && chkconfig keepalived on 
```
### 9. Start HAproxy and Keepalived on the master and check logs


```
[root@ip-10-0-1-207 ec2-user]# service haproxy start && service keepalived start 
[root@ip-10-0-1-207 ec2-user]# tail -n 30 /var/log/messages 
```
### 10. Start HAproxy and Keepalived on the slave and check logs


```
[root@ip-10-0-1-207 ec2-user]# service haproxy start && service keepalived start 
[root@ip-10-0-1-207 ec2-user]# tail -n 30 /var/log/messages 
```

## Downloads
[keepalived_initd.zip](https://github.com/exasol/Public-Knowledgebase/files/9936059/keepalived_initd.zip)


