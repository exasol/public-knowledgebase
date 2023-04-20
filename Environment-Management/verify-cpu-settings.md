# Verify CPU Settings 
## Background

The performance of an Exasol database depends largely on the number and speed of all CPU cores of its cluster nodes. For optimal performance, all database nodes should have the same CPU configuration meaning same number and type of CPU cores (homogeneous hardware setup). In heterogeneous setups, the slowest and least powerful node will determine and limit the performance of the whole database.

Apart from a node's hardware, the CPU configuration in OS and BIOS also has an impact on performance. For maximum performance the following settings are required

* BIOS settings: power management => maximum performance ([see here](https://docs.exasol.com/db/latest/administration/on-premise/installation/system_requirements.htm#DataNodeRequirements "Follow"))
* CPU Scaling Governor => performance ([see here](https://docs.exasol.com/db/latest/administration/on-premise/nodes/information_about_nodes.htm#ViewNodeProperties "Follow"))

These configurations will provide maximum performance at the expense of a higher power consumption. If one or both settings are missing (e.g. to save power), there can be performance losses up to factor 2 for exclusive or nearly exclusive queries that have a high amount of cores available.

Although these settings are typically set during installation, they may be changed during BIOS or database updates. 

## How to verify settings

You can verify if your CPU settings follow our best practices by running the following Python UDF. A broken node CPU configuration manifests in CPU cores running at quite different clock rates. This UDF reads those clock rates from /proc/cpuinfo and checks them for correct configuration.


```sql
--/
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT "EMIT_CPU_RATES" ("IPROC" INT) EMITS ("HOSTNAME" VARCHAR(120), "IPROC" INT, "CPU_MHZ" DOUBLE) AS 
def run(ctx):
    import re
    import platform
    hostname = platform.node().split('.', 1)[0]
    cpuinfo = open('/proc/cpuinfo').read()
    rates = re.findall('^cpu MHz\s*: *(?P<mhz>[\d.]+)', cpuinfo, re.MULTILINE)
    for r in rates:
        ctx.emit(hostname, ctx.IPROC, float(r))
/

WITH RATES AS (select EMIT_CPU_RATES(IPROC()) from exa_loadavg)
SELECT HOSTNAME, "IPROC", MIN(CPU_MHZ), MAX(CPU_MHZ), MIN(CPU_MHZ)/MAX(CPU_MHZ) > 0.98 AS FULL_POWER 
FROM RATES
GROUP BY HOSTNAME, "IPROC";
```
The script will return a line for every active database node and non-optimal setups will have a FALSE value in the column FULL_POWER.

## Next Steps

If the query returns FALSE for some nodes, then it is likely a CPU setting no longer follows best practices. In this case, review the following settings and set them to the recommended values as described above:

* BIOS power management settings
* CPU Scaling settings in EXAoperation or via cpupower command 

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 