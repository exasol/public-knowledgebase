# Install Docker Community Edition on RHEL and CentOS 7 
Docker is a PaaS "Platform as a Service" product that uses OS-level virtualization technology to deploy software in relatively small packages called containers that are completely isolated, have their own software, libraries, and even network. You can easily obtain our image via Github or Docker Hub. This tutorial below will show you how to install Docker on CentOS and other RHEL-based systems (however, the installed repo will vary).

**NOTE:** This method was tested on CentOS 7.7 

1. Update your Packages list:


```
$ sudo yum update
```
2. Install the necessary packages:


```
$ sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```
3. Add the official Docker repository:


```
$ sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo  (for CentOS )
$ sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo    (for RHEL)
$ sudo yum-config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo  (for Fedora)
```
4. Update the new packages list (you should see the Docker package list being downloaded):


```
$ sudo yum update
```
5. Install Docker Community Edition:


```
$ sudo yum install docker-ce -y
```
6. Check if Docker is running:


```
$ sudo systemctl status docker
```
6.1. If not running, run the following commands:


```
$ sudo systemctl start docker  
$ sudo systemctl enable docker
```
7. Run the "Hello World" container to verify:


```
$ docker run hello-world

...

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.
```
 8. Download other images via:


```
$ docker image pull <image_name>
```
After you finish the steps above you are ready to continue with installing your Exasol system. You can do so by following the instructions at [How to Deploy a Single-Node Exasol Database as a Docker Image for Testing Purposes](https://exasol.my.site.com/s/article/How-to-deploy-a-single-node-Exasol-database-as-a-Docker-image-for-testing-purposes).

