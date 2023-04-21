# Temporary failure in name resolution

## Question
I am taking Exasol Advanced Analytics course and struggling with below error

SQL Error [22002]: VM error: IOError: [Errno socket error] [Errno -3] Temporary failure in name resolution (Session: 1669598356062630871)

Below is my python script which works fine when I ran it in Python console:
```
CREATE OR REPLACE PYTHON SCALAR SCRIPT eur_to_usd(priceval DECIMAL(18,2)) RETURNS DECIMAL(18,2) AS  
import urllib  
import json  
s = urllib.urlopen('https://free.currconv.com/api/v7/convert?q=EUR_USD&compact=ultra&apiKey=2e3983a73cac34f7c737').read()  
data = json.loads(s)  
def run(ctx):  
return ctx.priceval * decimal.Decimal(data['EUR_USD'])  
/  

select fruits.*,eur_to_usd(price) from fruits
```
I have installed Python 3.8.3 on my system where few modification required to make this script work like "import urllib.request" instead of "import urllib". I am using Exasol community edition on Virtual Box. Even after restarting the virtual box did not resolve the issue. Kindly assist.

## Answer
This is likely a networking issue.  In VirtualBox you'll need to change the public network to connect to a bridged adapter, then restart the VM service.  Be aware that this will provide you with a different URL to to connect to EXAoperation and another connection string for your database client.  

You can also test your ability to reach the outside network by going into EXAoperation>Configuration>Network, and adding in Google's free DNS servers 8.8.8.8 and 8.8.4.4, and then running this in your database client:
```
create schema test;

--/  
CREATE OR REPLACE LUA SCALAR SCRIPT  
lua_connect(hostname varchar(4096), port varchar(4096))  
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
>
SELECT lua_connect('google.com', '80') res FROM dual;  
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 