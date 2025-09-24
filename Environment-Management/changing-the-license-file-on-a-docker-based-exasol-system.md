# Changing the license file on a Docker-based Exasol system

**Since database version 8 please use `confd_client` to manage licenses: [Upload a license](https://docs.exasol.com/db/latest/administration/on-premise/installation/install_as_app/upload_license.htm). Likely, this functionality will eventually be added to Admin UI.**

**Note:** $CONTAINER_EXA is a variable set before deploying an Exasol database container with persistent storage. For more information, please check [our Github repo](https://github.com/exasol/docker-db).

1. Ensure that your Docker container is running with persistent storage. This means that your docker run command should contain a **-v** statement, like the example below:

    ```shell
    docker run --detach --network=host --privileged --name <container_name> -v $CONTAINER_EXA:/exa exasol/docker-db:6.1.5-d1 init-sc --node-id <node_id>
    ```

2. Copy the new license file to the the `$CONTAINER_EXA/etc/` folder:

      ```shell
      cp /home/user/Downloads/new_license.xml $CONTAINER_EXA/etc/new_license.xml
      ```

3. Log in to your Docker container's BASH environment:

      ```shell
      docker exec -it <container_name> /bin/bash
      ```

4. Go to the `/exa/etc` folder and rename the old `license.xml` file:

      ```shell
      cd /exa/etc/  
      mv license.xml license.xml.old
      ```

5. Rename the new license file:

      ```shell
      mv new_license.xml license.xml
      ```

6. Double-check the contents of the directory, to ensure that the newer file is name `license.xml`:

      ```shell
      $ ls -l  
      <other files>  
      -rw-r--r-- 1 root root 2275 Jul 15 10:13 license.xml.old  
      -rw-r--r-- 1 root root 1208 Jul 21 07:38 license.xml  
      <other files>
      ```

7. Sync file across all nodes if you are using a multi-node cluster:

      ```shell
      cos_sync_files /exa/etc/license.xml  
      cos_sync_files /exa/etc/license.xml.old
      ```

8. Stop the Database and Storage services:

      ```shell
      dwad_client stop-wait <database_instance>
      csctrl -d
      ```

9. Restart the Container:

      ```shell
      docker restart <container_name>
      ```

10. Log in to the container and check if the proper license is installed:

      ```shell
      docker exec -it <container_name> /bin/bash  
      awk '/SHLVL/ {for(i=1; i<=6; i++) {getline; print}}' /exa/logs/cored/exainit.log | tail -6
      ```

      You should get an output similar to this:

      ```text
      [2020-07-21 09:43:50] stage0: You have following license limits:  
      [2020-07-21 09:43:50] stage0: >>> Database memory (GiB): 50 Main memory (RAM) usable by databases  
      [2020-07-21 09:43:50] stage0: >>> Database raw size (GiB): unlimited Raw Size of Databases (see Value RAW_OBJECT_SIZE in System Tables)  
      [2020-07-21 09:43:50] stage0: >>> Database mem size (GiB): unlimited Compressed Size of Databases (see Value MEM_OBJECT_SIZE in System Tables)  
      [2020-07-21 09:43:50] stage0: >>> Cluster nodes: unlimited Number of usable cluster nodes  
      [2020-07-21 09:43:50] stage0: >>> Expiration date: unlimited Date of license expiration
      ```

    Check the parameters and see if it corresponds to your requested license parameters.

## References

* [Upload a license](https://docs.exasol.com/db/latest/administration/on-premise/installation/install_as_app/upload_license.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
