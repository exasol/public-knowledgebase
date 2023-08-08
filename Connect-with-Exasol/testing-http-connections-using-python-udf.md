# Testing HTTP connections using python UDF 
## Background

As Exasol comes with its own operating system and users do rarely have access to that system, testing network connectivity can be quite hard. This makes debugging Import/Export/UDF that fail with **timeouts** or **connection refused** a lengthy task.

## How to test HTTP connections using python UDF

The attached SQL file contains a `SCALAR PYTHON3 SCRIPT` that does minimalistic network testing using the following steps:

1. **Hostname lookup** using DNS (Domain Name Service)
2. **TCP connect** to the resulting address
3. **HTTP 1.1 request**

The script will output some information, including the cluster node it ran on and an elapsed time (in seconds).

## Example usage

### 1 - Testing an internal web server on a random node

```sql
select webtest_py('192.168.0.186', 80, '/cluster1') order by 1,2;
```

|NODE_NAME_IP|MSG_NO|DURATION_SECONDS|MESSAGE|
|------------|------|----------------|-------|
|n0010.c0001.exacluster.local (27.1.0.10)|1|0.005|Checking DNS for 192.168.0.186|
|n0010.c0001.exacluster.local (27.1.0.10)|2|0.002|Name resolves to IPs ['192.168.0.186']|
|n0010.c0001.exacluster.local (27.1.0.10)|3|0.000|Trying to connect to 192.168.0.186, port 80|
|n0010.c0001.exacluster.local (27.1.0.10)|4|0.001|Connected.|
|n0010.c0001.exacluster.local (27.1.0.10)|5|0.008|HTTP GET request sent|
|n0010.c0001.exacluster.local (27.1.0.10)|6|0.249|HTTP/1.1 200 Ok|
|n0010.c0001.exacluster.local (27.1.0.10)|7|0.000|...Content-Length: 6534|
|n0010.c0001.exacluster.local (27.1.0.10)|8|0.003|...X-XSS-Protection: 1;mode=block|
|n0010.c0001.exacluster.local (27.1.0.10)|9|0.000|...X-Content-Type-Options: nosniff|
|n0010.c0001.exacluster.local (27.1.0.10)|10|0.000|...Set-Cookie: __csrftoken__=494GPLCLKTI1NGZ9CPC993CCIM6P92E5; httponly; Path=/|
|n0010.c0001.exacluster.local (27.1.0.10)|11|0.000|...Server: |
|n0010.c0001.exacluster.local (27.1.0.10)|12|0.000|...Date: Wed, 02 Aug 2023 15:51:18 GMT|
|n0010.c0001.exacluster.local (27.1.0.10)|13|0.000|...X-Frame-Options: SAMEORIGIN|
|n0010.c0001.exacluster.local (27.1.0.10)|14|0.000|...Content-Type: text/html;charset=utf-8|
|n0010.c0001.exacluster.local (27.1.0.10)|15|0.000|End of headers|

### 2 - Invalid page

```sql
select webtest_py('192.168.0.186', 80, '/xxx.html') order by 1,2;
```

|NODE_NAME_IP|MSG_NO|DURATION_SECONDS|MESSAGE|
|------------|------|----------------|-------|
|n0010.c0001.exacluster.local (27.1.0.10)|1|0.005|Checking DNS for 192.168.0.186|
|n0010.c0001.exacluster.local (27.1.0.10)|2|0.000|Name resolves to IPs ['192.168.0.186']|
|n0010.c0001.exacluster.local (27.1.0.10)|3|0.000|Trying to connect to 192.168.0.186, port 80|
|n0010.c0001.exacluster.local (27.1.0.10)|4|0.001|Connected.|
|n0010.c0001.exacluster.local (27.1.0.10)|5|0.002|HTTP GET request sent|
|n0010.c0001.exacluster.local (27.1.0.10)|6|0.000|HTTP/1.1 403 Forbidden|
|n0010.c0001.exacluster.local (27.1.0.10)|7|0.000|...Date: Wed, 02 Aug 2023 15:56:06 GMT|
|n0010.c0001.exacluster.local (27.1.0.10)|8|0.000|...Content-Length: 163|
|n0010.c0001.exacluster.local (27.1.0.10)|9|0.000|...Content-Type: text/html; charset=utf-8|
|n0010.c0001.exacluster.local (27.1.0.10)|10|0.000|...Server: |
|n0010.c0001.exacluster.local (27.1.0.10)|11|0.000|End of headers|

### 3 - Trying wrong port:

```sql
select webtest_py('192.168.0.186', 30, '/') order by 1,2;
```

|NODE_NAME_IP|MSG_NO|DURATION_SECONDS|MESSAGE|
|------------|------|----------------|-------|
|n0010.c0001.exacluster.local (27.1.0.10)|1|0.006|Checking DNS for 192.168.0.186|
|n0010.c0001.exacluster.local (27.1.0.10)|2|0.000|Name resolves to IPs ['192.168.0.186']|
|n0010.c0001.exacluster.local (27.1.0.10)|3|0.000|Trying to connect to 192.168.0.186, port 30|
|n0010.c0001.exacluster.local (27.1.0.10)|4|0.000|Failed: [Errno 111] Connection refused|

### 4 - Firewall blocks external connection from all nodes:

```sql
select webtest_py('www.heise.de', 80, '/') from exa_loadavg order by 1,2; 
```

|NODE_NAME_IP|MSG_NO|DURATION_SECONDS|MESSAGE|
|------------|------|----------------|-------|
|n0011.c0001.exacluster.local (27.1.0.11)|1|0.003|Checking DNS for www.heise.de|
|n0011.c0001.exacluster.local (27.1.0.11)|2|0.042|Name resolves to IPs ['193.99.144.85']|
|n0011.c0001.exacluster.local (27.1.0.11)|3|0.000|Trying to connect to 193.99.144.85, port 80|
|n0011.c0001.exacluster.local (27.1.0.11)|4|127.278|Failed: [Errno 110] Connection timed out|
|n0012.c0001.exacluster.local (27.1.0.12)|1|0.002|Checking DNS for www.heise.de|
|n0012.c0001.exacluster.local (27.1.0.12)|2|0.044|Name resolves to IPs ['193.99.144.85']|
|n0012.c0001.exacluster.local (27.1.0.12)|3|0.000|Trying to connect to 193.99.144.85, port 80|
|n0012.c0001.exacluster.local (27.1.0.12)|4|128.321|Failed: [Errno 110] Connection timed out|

## Additional References

The script itself: [webtest_py.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/webtest_py.sql)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 