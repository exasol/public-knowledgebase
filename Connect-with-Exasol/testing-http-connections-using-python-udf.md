# Testing HTTP connections using python UDF 
## Background

As Exasol comes with its own operating system and users do rarely have access to that system, testing network connectivity can be quite hard. This makes debugging Import/Export/UDF that fail with **timeouts** or **connection refused** a lengthy task.

## How to test HTTP connections using python UDF

The attached SQL file contains aSCALAR PYTHON SCRIPTthat does minimalistic network testing using the following steps:

1. **Hostname lookup** using DNS (Domain Name Service)
2. **TCP connect** to the resulting address
3. **HTTP 1.1 request**

The script will output some information, including the cluster node it ran on and an elapsed time (in seconds).

## Example usage

### 1 - Testing an internal web server on a random node


```"code-sql"
select webtest_py('192.168.103.212', 80, '/') order by 1,2; 
```


| NODE_IP | SECONDS | MESSAGE |
| --- | --- | --- |
| n0016.c0001.exacluster.local | 0.009 | Checking DNS for 192.168.103.212 |
| n0016.c0001.exacluster.local | 0.009 | Name resolves to IPs['192.168.103.212'] |
| n0016.c0001.exacluster.local | 0.009 | Trying to connect to 192.168.103.212, port 80 |
| n0016.c0001.exacluster.local | 0.010 | Connected. |
| n0016.c0001.exacluster.local | 0.010 | HTTP GET request sent |
| n0016.c0001.exacluster.local | 0.011 | HTTP/1.1 200 OK |
| n0016.c0001.exacluster.local | 0.011 | ...Date: Mon, 12 Oct 2015 14:37:19 GMT |
| n0016.c0001.exacluster.local | 0.011 | ...Server: Apache/2.2.9 (Debian) mod_auth_kerb/5.3 DAV/2 SVN/1.5.1 PHP/5.2.6-1+lenny16 with Suhosin-Patch mod_ssl/2.2.9 OpenSSL/0.9.8g |
| n0016.c0001.exacluster.local | 0.011 | ...Last-Modified: Mon, 16 Jun 2008 08:57:00 GMT |
| n0016.c0001.exacluster.local | 0.011 | ...ETag: "50800c-128-44fc4cf7b6f00" |
| n0016.c0001.exacluster.local | 0.011 | ...Accept-Ranges: bytes |
| n0016.c0001.exacluster.local | 0.011 | ...Content-Length: 296 |
| n0016.c0001.exacluster.local | 0.011 | ...Vary: Accept-Encoding |
| n0016.c0001.exacluster.local | 0.011 | ...Content-Type: text/html |
| n0016.c0001.exacluster.local | 0.011 | End of headers |

### 2 - Invalid page


```"code-sql"
select webtest_py('192.168.103.212', 80, '/xxx.html') order by 1,2; 
```


| NODE_IP | SECONDS | MESSAGE |
| --- | --- | --- |
| n0016.c0001.exacluster.local | 0.002 | Checking DNS for 192.168.103.212 |
| n0016.c0001.exacluster.local | 0.002 | Name resolves to IPs['192.168.103.212'] |
| n0016.c0001.exacluster.local | 0.003 | Trying to connect to 192.168.103.212, port 80 |
| n0016.c0001.exacluster.local | 0.003 | Connected. |
| n0016.c0001.exacluster.local | 0.003 | HTTP GET request sent |
| n0016.c0001.exacluster.local | 0.004 | HTTP/1.1 404 Not Found |
| n0016.c0001.exacluster.local | 0.004 | ...Date: Mon, 12 Oct 2015 14:50:31 GMT |
| n0016.c0001.exacluster.local | 0.005 | ...Server: Apache/2.2.9 (Debian) mod_auth_kerb/5.3 DAV/2 SVN/1.5.1 PHP/5.2.6-1+lenny16 with Suhosin-Patch mod_ssl/2.2.9 OpenSSL/0.9.8g |
| n0016.c0001.exacluster.local | 0.005 | ...Vary: Accept-Encoding |
| n0016.c0001.exacluster.local | 0.005 | ...Content-Length: 388 |
| n0016.c0001.exacluster.local | 0.005 | ...Content-Type: text/html; charset=iso-8859-1 |
| n0016.c0001.exacluster.local | 0.005 | End of headers |

### 3 - Trying wrong port:


```"code-sql"
select webtest_py('192.168.103.212', 20, '/') order by 1,2; 
```


| NODE_IP | SECONDS | MESSAGE |
| --- | --- | --- |
| n0016.c0001.exacluster.local | 0.013 | Checking DNS for 192.168.103.212 |
| n0016.c0001.exacluster.local | 0.013 | Name resolves to IPs['192.168.103.212'] |
| n0016.c0001.exacluster.local | 0.014 | Trying to connect to 192.168.103.212, port 20 |
| n0016.c0001.exacluster.local | 0.014 | Failed:[Errno 111]Connection refused |

### 4 - Firewall blocks external connection from all nodes:


```"code-sql"
select webtest_py('www.heise.de', 80, '/') from exa_loadavg order by 1,2; 
```


| NODE_IP | SECONDS | MESSAGE |
| --- | --- | --- |
| n0016.c0001.exacluster.local | 0.002 | Checking DNS for [www.heise.de](http://www.heise.de) |
| n0016.c0001.exacluster.local | 0.003 | Name resolves to IPs['193.99.144.85'] |
| n0016.c0001.exacluster.local | 0.004 | Trying to connect to 193.99.144.85, port 80 |
| n0016.c0001.exacluster.local | 63.004 | Failed:[Errno 110]Connection timed out |
| n0017.c0001.exacluster.local | 0.009 | Checking DNS for [www.heise.de](http://www.heise.de) |
| n0017.c0001.exacluster.local | 0.011 | Name resolves to IPs['193.99.144.85'] |
| n0017.c0001.exacluster.local | 0.011 | Trying to connect to 193.99.144.85, port 80 |
| n0017.c0001.exacluster.local | 63.011 | Failed:[Errno 110]Connection timed out |
| n0019.c0001.exacluster.local | 0.009 | Checking DNS for [www.heise.de](http://www.heise.de) |
| n0019.c0001.exacluster.local | 0.011 | Name resolves to IPs['193.99.144.85'] |
| n0019.c0001.exacluster.local | 0.011 | Trying to connect to 193.99.144.85, port 80 |
| n0019.c0001.exacluster.local | 63.011 | Failed:[Errno 110]Connection timed out |
| n0020.c0001.exacluster.local | 0.002 | Checking DNS for [www.heise.de](http://www.heise.de) |
| n0020.c0001.exacluster.local | 0.003 | Name resolves to IPs['193.99.144.85'] |
| n0020.c0001.exacluster.local | 0.004 | Trying to connect to 193.99.144.85, port 80 |
| n0020.c0001.exacluster.local | 63.003 | Failed:[Errno 110]Connection timed out |

## Downloads
[webtest_py.zip](https://github.com/exasol/Public-Knowledgebase/files/9936499/webtest_py.zip)
