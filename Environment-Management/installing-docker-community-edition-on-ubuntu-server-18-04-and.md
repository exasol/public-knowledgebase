# Installing Docker Community Edition on Ubuntu Server 18.04 and 20.04 
Docker is a PaaS "Platform as a Service" product that uses OS-level virtualization technology to deploy software in relatively small packages called containers that are completely isolated, have their own software, libraries, and even network. Exasol supports Docker as a platform and you can easily obtain our image via Github or Docker Hub. This tutorial below will show you how to install Docker on Ubuntu and other Debian-based systems (however, the installed repo will vary).

**NOTE:** This method was tested on Ubuntu Server 18.04 (Bionic Beaver) and 20.04 ( Focal Fossa)

1. Update your Packages list:


```
$ sudo apt update
```
2. Install the necessary packages:


```
$ sudo apt install apt-transport-https ca-certificates curl software-properties-common -
```
3. Add the GPG keys for the Docker repository:


```
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```
4. Add the official Docker repository:


```
$ sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" (for 18.04)  
$ sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" (for 20.04)
```
5. Update the new packages list (you should see the Docker package list being downloaded):


```
$ sudo apt update
```
6. Install Docker Community Edition:


```
$ sudo apt install docker-ce -y
```
7. Check if Docker is running:


```
$ sudo systemctl status docker
```
7.1. If not running, run the following commands:


```
$ sudo systemctl start docker  
$ sudo systemctl enable docker
```
8. Run the "Hello World" container to verify:


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
 9. Download other images via:


```
$ docker image pull <image_name> 
```
After you finish the steps above you are ready to continue with installing your Exasol system. You can do so by following the instructions at [How to Deploy a Single-Node Exasol Database as a Docker Image for Testing Purposes](https://exasol.my.site.com/s/article/How-to-deploy-a-single-node-Exasol-database-as-a-Docker-image-for-testing-purposes).

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 