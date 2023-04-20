# How to get debug information and log files from docker based systems 

In order to get debug information and log files, the tool "exasupport" can be used. There is no installation required, the tool comes preinstalled with the docker image. 

## Step 1

Launch a *Bash* terminal within a container:


```python
docker exec -it {CONTAINER_NAME} bash
```
## Step 2

The command "exasupport --help" will return detailed information about the command:


```python
[root@n11 /]# exasupport --help
Usage: exasupport [options]

Retrieve support information

Options:
  -h, --help            show this help message and exit
  -d DEBUGINFO, --debug-info=DEBUGINFO
                        Debuginfo to retrieve, separated by comma: 1 =
                        EXAClusterOS logs, 2 = Coredumps, 3 = EXAStorage
                        metadata or 0 for all
  -s START_DATE, --start-time=START_DATE
                        Start time of logs (YYYY-MM-DD [HH:MM])
  -t STOP_DATE, --stop-time=STOP_DATE
                        Stop time of logs (YYYY-MM-DD [HH:MM])
  -e EXASOLUTION, --exasolution=EXASOLUTION
                        EXASolution logs (System names, separated by comma or
                        "All databases")
  -x EXASOLUTION_LOG_TYPE, --exasolution-log-type=EXASOLUTION_LOG_TYPE
                        EXASolution log type, separated by comma (1 = All, 2 =
                        SQL processes, 3 = Server processes)
  -i SESSION, --session=SESSION
                        Get logs from specific sessions, separated by comma
  -b BACKTRACES, --backtraces=BACKTRACES
                        Process backtraces 1 = EXASolution server processes, 2
                        = EXASolution SQL processes, 3 = EXAClusterOS
                        processes, 4 = ETL JDBC Jobs
  -n NODES, --nodes=NODES
                        Nodes (default: all online nodes)
  -a, --only-archives   Only download archives
  -f, --only-open-files
                        Only download open files
  -m, --estimate        Only estimate size of debug information
  -o OUTFILE, --outfile=OUTFILE
                        Output file
```
## Step 3

An example: To get all server processes and sql log file for specific session ID and date period, you can use:


```python
exasupport -d 0 -s 2020-10-25 -t 2020-10-26 -e {DATABASE_NAME} -x 1 -i {SESSION_ID}
```


If you don't know the database name, you can use the command "**dwad_client shortlist"** to get it.

## Step 4

The command above will create a tar.gz file in the folder /exa/tmp/support.


```python
[root@n11 /]# exasupport -d 0 -s 2020-10-25 -t 2020-10-26 -e {DATABASE_NAME} -x 1 -i {SESSION_ID}
Successfully stored debug information into file /exa/tmp/support/exacluster_debuginfo_2020_10_26-11_20_01.tar.gz

[root@n11 /]# ls -lrt /exa/tmp/support/
total 492
-rwxr-xr-x 1 root root 503265 Oct 26 11:20 exacluster_debuginfo_2020_10_26-11_20_01.tar.gz
[root@n11 /]#
```
## Step 5

You can access this folder from the host system. If you used the article <https://exasol.my.site.com/s/article/How-to-deploy-a-single-node-Exasol-database-as-a-Docker-image-for-testing-purposes> then all of your configuration and log files are stored in  the $CONTAINER_EXA (/root/container_exa) folder.


```python
root@host001:~# ls $CONTAINER_EXA/tmp/support/ 
exacluster_debuginfo_2020_10_26-11_20_01.tar.gz
```
## Additional References

<https://exasol.my.site.com/s/article/How-to-deploy-a-single-node-Exasol-database-as-a-Docker-image-for-testing-purposes>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 