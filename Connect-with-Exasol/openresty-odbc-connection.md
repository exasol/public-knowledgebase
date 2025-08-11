# OpenResty Exasol ODBC connection

## Background

Connecting to Exasol from OpenResty lets you build fast APIs or dynamic web endpoints directly inside Nginx using Lua.
This enables you to query Exasol on the fly and return results to clients without an extra backend layer.

## Steps

Below are steps to connect to Exasol from Openresty.

* Install openresty [Openresty Installation manual](https://openresty.org/en/linux-packages.html#ubuntu)
* install Luarocks

```shell
wget https://github.com/luarocks/luarocks/archive/v3.0.0.tar.gz

tar zxvf v3.0.0.tar.gz

./configure --prefix=/usr/local/openresty/luajit/ --with-lua=/usr/local/openresty/luajit/ --lua-suffix=jit --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1

sudo make build

sudo make install
```

* install ODBC package in luarocks

```shell
luarocks install odbc
```

* install Exasol ODBC driver, create DSN for Exasol DB [ODBC Drivers for Linux/FreeBSD | Exasol Documentation](https://docs.exasol.com/db/latest/connect_exasol/drivers/odbc/odbc_linux.htm)

* Execute connection test scripts

 odbctest.sh

```shell
# set -x
# ORHOME is the path to the OpenResty install
export ORHOME="/usr/local/openresty"
export ODBCINI="${ORHOME}/odbc/.odbc.ini"
export LD_LIBRARY_PATH="${ORHOME}/luajit/lib"
export PATH="$PATH:${ORHOME}/bin/"
resty odbctest.lua $1
echo "Retun code from resty $?"
```

 odbctest.lua

```lua
local odbc = require("odbc")
local call = [[select * from sys.exa_all_tables]]
print("Using dsn " .. arg[1])
local DSN = arg[1]
   print("About to connect")
local cnn,err = odbc.connect(DSN)
if cnn == nil then
   print("Failed to connect" .. err.message)
else
   print("Connected")
end
local stmt,err = cnn:statement()
if stmt == nil then
   print("Failed to prepare Statement" ..err.message)
else
   print("Prepared statement" )
end
local ret,err = stmt:execute(call)
if ret == nil then
   print("Failed to execute statement" .. err.message)
else
   print("Executed satement")
end
local cols = ret:colnames()
if string.upper(cols[1]) == [[ERR]] then
   -- There has been some sort of error
   print("Some sort of error was raised " .. ret:fetch())
end
```

## Additional References

* [Openresty Installation manual](https://openresty.org/en/linux-packages.html#ubuntu)
* [ODBC Drivers for Linux/FreeBSD | Exasol Documentation](https://docs.exasol.com/db/latest/connect_exasol/drivers/odbc/odbc_linux.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
