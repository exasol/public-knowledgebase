# How to Collect PyExasol Debug Logs

## Background

PyExasol can output debug information for connection attempts and client-server communication. These logs are useful when a Python application cannot connect to Exasol, receives unexpected driver errors, or needs request and response details for troubleshooting.

Use PyExasol debug logging only while reproducing the issue. Debug output can include SQL text, connection details, and other information from the application session.

## Prerequisites

Before you collect PyExasol debug logs, make sure that you have:

* A Python environment with PyExasol installed.
* A PyExasol, Python, and Exasol database version combination that is supported by PyExasol.
* A script or notebook that can reproduce the issue.
* Permission to write a log file or create a log directory on the client machine.

## How to Collect PyExasol Debug Logs

### Step 1

Enable debug logging in the PyExasol connection and set a directory where PyExasol can store the debug files.

```python
import pyexasol

with pyexasol.connect(
    dsn="your-exasol-host:8563",
    user="your-user",
    password="your-password",
    encryption=True,
    debug=True,
    debug_logdir="pyexasol-debug-logs",
) as connection:
    connection.execute("SELECT 1")
```

With `debug=True` and `debug_logdir`, PyExasol writes debug information to files in the specified directory.

### Step 2

Run the Python script or application and reproduce the issue. After the issue is reproduced, stop the script or close the connection so that the final debug output is written.

### Step 3

Review the generated log file or files before you share them. Remove sensitive information that is not needed for troubleshooting, such as SQL literals, usernames, hostnames, DSNs, tokens, passwords, and business data.

When opening a support case, include the following context with the PyExasol logs:

* PyExasol version.
* Python version.
* Exasol database version.
* Operating system of the client machine.
* Approximate time when the issue was reproduced.
* Session ID, if the script connected successfully.
* The error message or stack trace from the application.

## Additional Notes

PyExasol debug logs are client-side logs. They are different from Exasol database server logs, JDBC logs, ODBC logs, and UDF script output logs.

If the issue involves UDF output, use PyExasol UDF script output debugging instead of the connection debug options. This feature requires the Exasol nodes to connect back to the TCP server that captures script output.

Disable `debug=True` after troubleshooting is complete.

## Additional References

* [PyExasol Documentation](pyExasol-documetation.md)
* [PyExasol Getting Started](https://exasol.github.io/pyexasol/master/user_guide/getting_started.html)
* [PyExasol API Reference](https://exasol.github.io/pyexasol/master/api.html)
* [PyExasol UDF Script Output Debugging](https://exasol.github.io/pyexasol/master/user_guide/exploring_features/debugging_udf_script_output.html)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
