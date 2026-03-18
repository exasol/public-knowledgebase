# Connection from Oracle Data Integrator (ODI) fails with "Connection Properties does not support ... argument"

## Problem

You try to configure a connection from Oracle Data Integrator (ODI) to Exasol database and receive an error like:

```text
oracle.odi.runtime.agent.invocation.InvocationException: oracle.odi.core.exception.OdiRuntimeException: java.sql.SQLException:
[ERROR] Connection Properties does not support (ENC_KEY) argument.
at oracle.odi.runtime.agent.invocation.RemoteRuntimeAgentInvoker.invoke(RemoteRuntimeAgentInvoker.java:483)
at oracle.odi.runtime.agent.invocation.support.InternalRemoteRuntimeAgentInvoker.invoke(InternalRemoteRuntimeAgentInvoker.java:162)
at oracle.odi.runtime.agent.invocation.RemoteRuntimeAgentInvoker.invokeTestDataServer(RemoteRuntimeAgentInvoker.java:1996)
at com.sunopsis.graphical.dialog.SnpsDialogTestConnet.remoteTestConn(SnpsDialogTestConnet.java:1080)
at com.sunopsis.graphical.dialog.SnpsDialogTestConnet$12.doInBackground(SnpsDialogTestConnet.java:1038)
at oracle.odi.ui.framework.AbsUIRunnableTask.run(AbsUIRunnableTask.java:258)
at oracle.ide.dialogs.ProgressBar.run(ProgressBar.java:961)
at java.lang.Thread.run(Thread.java:750)
```

Instead of parameter name "ENC_KEY" it could contain another one.

## Solution

Since version 24.2.0 Exasol JDBC driver detects if connection string or connection properties contain unsupported parameters and throws the following error

```text
Exception:
[ERROR] Connection String does not support ([ARGUMENT]) argument.
```

or

```text
Exception:
[ERROR] Connection Properties does not support ([ARGUMENT]) argument.
```

based on where the wrong parameter was found. See also [CHANGELOG: Exasol JDBC Driver should throw error on invalid parameter in connection string and connection string properties](https://exasol.my.site.com/s/article/Changelog-content-21749?language=en_US).

Therefore, the original error thrown by ODI

```text
Connection Properties does not support (ENC_KEY) argument.
```

means that it adds parameter `ENC_KEY`, unsupported by Exasol JDBC driver, to the JDBC connection properties.

The easiest way to address this is to instruct Exasol JDBC driver to ignore some provided unknown connection properties. It can be done by using JDBC driver's parameter `ignoreparams` (see [JDBC Driver](https://docs.exasol.com/db/latest/connect_exasol/drivers/jdbc.htm)):

| Property | Value type | Description |
| - | - | - |
| ignoreparams | string | Optional comma-separated list of string parameters to be ignored by the driver’s spell checker. <br /> For example: ignoreparams=someparam,abcxyz |

In our tests ignoring the following parameters was enough:

```java
ignoreparams=ENC_KEY,ENC_ALGO,enc_iv,enc_key_len
```

You might need to adapt the parameter list in your setup, based on exact received error message.

## Additional References

* [CHANGELOG: Exasol JDBC Driver should throw error on invalid parameter in connection string and connection string properties](https://exasol.my.site.com/s/article/Changelog-content-21749?language=en_US)
* [CHANGELOG: JDBC Improved Handling of Invalid Connection String Parameters](https://exasol.my.site.com/s/article/Changelog-content-19621?language=en_US)
* [CHANGELOG: Improved ignoreparams Handling in Exasol JDBC Driver](https://exasol.my.site.com/s/article/Changelog-content-26259?language=en_US)
* [JDBC Driver](https://docs.exasol.com/db/latest/connect_exasol/drivers/jdbc.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
