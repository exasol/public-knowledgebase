# Updating a Docker-based Exasol System (6.1.X -&gt; 6.2.X) 
**WHAT WE'LL LEARN?**

In this article you will learn how to update a Docker-based Exasol system.

**HOW-TO**

1. Ensure that your Docker container is running with persistent storage. This means that your docker run command should contain a ***-v***statement, like the example below:


```
$ docker run --detach --network=host --privileged --name *<container_name>* -v $CONTAINER_EXA:/exa exasol/docker-db:6.2.8-d1 init-sc --node-id *<node_id>*
```
2. Log in to your Docker container's BASH environment:


```
$ docker exec -it *<container_name>* /bin/bash
```
 3. Stop the database, storage services and exit the container:


```
$ dwad_client stop-wait *<database_instance>*$ csctrl -d  
$ exit
```
4. Stop the container:


```
$ docker stop *$container_name*
```
5. Rename the existing container. Append with *old*, so that you know that this is the container which you won't be using anymore


```
$ docker rename *<container_name> <container_name_**old**>*
```
6. Create a new tag for the older container image:


```
$ docker tag exasol/docker-db:latest exasol/docker-db:older_image
```
7. Remove the ***"latest"*** tag for the ***"older_image"***:


```
$ docker rmi exasol/docker-db:latest
```
8. Pull the latest Docker-based Exasol image:


```
$ docker image pull exasol/docker-db:latest
```
8.1. Or pull the specific version you want. You can view the available versions and pull one of them with the commands bellow:


```
$ wget -q https://registry.hub.docker.com/v1/repositories/exasol/docker-db/tags -O - | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n' | awk -F: '{print $3}'  
  
...  
6.2.3-d1  
6.2.4-d1  
6.2.5-d1  
...  
  
$ docker image pull exasol/docker-db:*<image_version>*
```
 9. Run the following command to execute the update:


```
$ docker run --privileged --rm -v $CONTAINER_EXA:/exa -v *<all_other_volumes>* exasol/docker-db:latest update-sc  
or  
$ docker run --privileged --rm -v $CONTAINER_EXA:/exa -v *<all_other_volumes>* exasol/docker-db:*<image_version>* update-sc
```
Output should be similar to this:


```
Updating EXAConf '/exa/etc/EXAConf' from version '6.1.5' to '6.2.0'  
Container has been successfully updated!  
- Image ver. : 6.1.5-d1 --> 6.2.0-d1  
- DB ver. : 6.1.5 --> 6.2.0  
- OS ver. : 6.1.5 --> 6.2.0  
- RE ver. : 6.1.5 --> 6.2.0  
- EXAConf : 6.1.5 --> 6.2.0
```
 10. Run the container(s) the same way as you did before. Example:


```
$ docker run --detach --network=host --privileged --name *<container_name>* -v $CONTAINER_EXA:/exa exasol/docker-db:latest init-sc --node-id *<node_id>*
```
11. You can check the status of your booting container (optional):


```
$ docker logs *<container_name>* -f
```
12. You can remove the old container (optional):


```
$ docker rm *<container_name_old>*
```
