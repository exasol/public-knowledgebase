# How to start Exaplus CLI in Background Mode 
## Problem

When I start EXAplus in background mode using '&', it goes into "stopped" mode, even when using 'nohup'. 

## Diagnosis

EXAplus is primarily designed to be an interactive tool, so it tries to communicate with your terminal/console for various reasons. Most terminals stop the application at that point when it is running in background mode.

## Solution

Add the commandline switch '-pipe' to Exaplus

This switch will put Exaplus CLI into non-interactive mode, among others disabling the login dialog (user/password) and tab-completion (which usually is a bad idea on automated input).

## Additional References

* [List of Exaplus Parameters](https://docs.exasol.com/connect_exasol/sql_clients/exaplus_cli/exaplus_cli.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 