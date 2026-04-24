# Where is profiles.xml for EXAplus, and how do I use a profile in a cron job?

## Question

I want to run scripts such as `KILL_IDLE_SESSIONS()` and `KILL_ACTIVE_LONG_SESSIONS()` from a shell script that calls EXAplus through `cron`.

EXAplus has a `-profile` parameter, but the help text only says that the profile must exist in `<configDir>/profiles.xml`. It does not clearly state where `<configDir>` is located on Linux. I want to avoid putting the database password directly into the cron command.

## Answer

On Linux, EXAplus profiles are typically stored in `~/.exasol/profiles.xml` for the OS user that runs the command. This means that the profile must be created by the same Linux user that will later execute the cron job.

The path to the EXAplus executable can vary depending on the EXAplus version and how it was installed. In the examples below, replace `/path/to/exaplus` with the actual path in your environment.

If you do not know the path, you can usually find it on Linux with:

```shell
which exaplus
```

Create the profile once with the `-wp` option:

```shell
/path/to/exaplus \
 -wp <profile_name> \
 -c <hostname_or_ip>/<fingerprint>:8563 \
 -u sys \
 -p 'MyPassword123'
```

This creates or updates the file `~/.exasol/profiles.xml`.

In this example, `<profile_name>` is any profile name that you choose.

In this example, the connection string is shown as `<hostname_or_ip>/<fingerprint>:8563` to make the syntax easier to read. If the TLS certificate is already trusted, you can usually omit the fingerprint and use `<hostname_or_ip>:8563` instead.

After that, the cron job can use the saved profile instead of passing the password on the command line:

```shell
/path/to/exaplus \
 -profile <profile_name> \
 -q \
 -sql "EXECUTE SCRIPT DWH.KILL_IDLE_SESSIONS();"
```

You can use the same pattern for other scheduled scripts, for example:

```shell
/path/to/exaplus \
 -profile <profile_name> \
 -q \
 -sql "EXECUTE SCRIPT DWH.KILL_ACTIVE_LONG_SESSIONS();"
```

Because the saved profile contains the connection details, including the hashed password, protect the file with Linux file permissions so that only the intended OS user can read it.

For example:

```shell
chmod 700 ~/.exasol
chmod 600 ~/.exasol/profiles.xml
```

## Additional References

* [Scheduling Database Jobs](scheduling-database-jobs.md)
* [EXAplus CLI](https://docs.exasol.com/db/latest/connect_exasol/sql_clients/exaplus_cli/exaplus_cli.htm)
* [EXAplus 7.1 CLI parameters](https://docs.exasol.com/db/7.1/connect_exasol/sql_clients/exaplus_cli/exaplus_cli.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
