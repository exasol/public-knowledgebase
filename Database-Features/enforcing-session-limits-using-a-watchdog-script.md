# Enforcing session limits using a watchdog script 
## Background

While Exasol does not provide configurable limits on resource usage of single sessions, many administrators ask us how to impose such limits manually.

The simplest way to do this is to monitor the EXA_ALL_SESSIONS system table to identify "bad" sessions based on some criteria, and subsequently kill/abort these sessions.

## How to Implement

The attached (Lua) script implements such a watchdog and can be run (execute script) by a scheduled process.  
In its current form, it introduces three criteria for "bad" sessions:

* Sessions that use up too much TEMP_DB_RAM
* Sessions that have been active for too long
* Sessions that have been IDLE for too long

The configuration is embedded in the top of the script, where different limits can be set for different users (sorry, no roles yet):


```"noformat
	local USER_LIMITS = {
		USER1 = { query_timeout = 300, temp_ram = 3000, idle_timeout = 1800 },
		USER2  = { query_timeout = 150, idle_timeout = 300 },
		SYS = { temp_ram = 10000 }
	}
```
The above example will impose resource limits per session for three database users, with different criteria each.

## Additional Notes

Please remember that everything inside Lua is **case-sensitive** and so are the user names and variables configured above!

The script will check all current sessions against the given limits and will call

* KILL STATEMENT <...> IN SESSION <...> when a session exceeds any of the given limits
* KILL SESSION <...> when the limit is exceeded by more than 10 percent.

## Downloads
[session_watchdog.zip](https://github.com/exasol/Public-Knowledgebase/files/9937010/session_watchdog.zip)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 