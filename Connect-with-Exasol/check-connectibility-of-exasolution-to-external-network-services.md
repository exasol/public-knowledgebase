# Check connectibility of EXASolution to external network services 
## Background

When connecting to external network services from a database (e.g. via IMPORT/EXPORT commands or scripts), a user may not know if such a connection is at least possible. This may be due to

1. firewalls that block or abort connections, 
2. missing network routes,
3. temporary network issues,
4. missing DNS entries, etc.

## How to check network connectivity between Exasol and a Host

Here are two examples to easily check the network connectivity of an Exasol database to a host with IP address 192.168.2.1 and TCP port 80 with the help of scripting. As a return code, these scripts either return "OK" in case of success or an exception.

#### Lua


```"code-sql"
CREATE OR REPLACE LUA SCALAR SCRIPT lua_connect(hostname varchar(4096), port varchar(4096)) 
 RETURNS varchar(4096) 
 AS 
 socket = require("socket") 
 function run(ctx)     
 sock = assert(socket.tcp())     
 assert(sock:connect(ctx.hostname, ctx.port))     
 sock:close()     
 return 'OK' 
 end 
 /  
 
SELECT lua_connect('192.168.2.1', '80') res FROM dual; 
```
#### Python


```"code-sql"
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT
python_connect(hostname varchar(4096), port varchar(4096))
RETURNS varchar(4096)
AS
import socket

def run(ctx):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((ctx.hostname, int(ctx.port)))
    sock.close()
    return 'OK'
/

SELECT python_connect('192.168.2.1', '80') res FROM dual;
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 