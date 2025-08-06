# EXAplus and openJDK

## Problem

After openJDK was successfully installed EXAplus still won't start with an error message like

```text
Can not find the Java Runtime Environment needed by EXAplus.  
Trying to use system wide virtual machine (from registry) instead.  
No 64 bit java virtual machine found in registry.
```

## Diagnosis

EXAplus required a java runtime instance and proper registry entries to start.

According to [CHANGELOG: EXAplus on Windows will use Java from the current console](https://exasol.my.site.com/s/article/Changelog-content-18724?language=en_US) since version 24.0.0 of EXAplus it uses the Java interpreter set in the PATH variable of the console where it is started.

## Solution

### 1. Verify openJDK installation

Execute command "java -version" on the command line

A possible output may look like

```text
openjdk 11.0.2 2019-01-15  
OpenJDK Runtime Environment 18.9 (build 11.0.2+9)  
OpenJDK 64-Bit Server VM 18.9 (build 11.0.2+9, mixed mode)
```

The next step depends on what you downloaded, a JRE only or the complete JDK.

### 2.

#### a) JDK

It comes with a MSI installer and works as any other windows installer and does the necessary registry entries.  
But EXAplus needs a JRE instance to start. Contrary to Oracles installation, there's no own "jre" folder  
in the installation path of the JDK. Just create one and copy all contents again to this folder and EXAplus  
should start.

#### 2.b) JRE

The JRE is only a ZIP file and doesn't edit registry during the unzip to the desired folder. You can edit the registry using the Registry Editor.

- edit existing registry entries manually  
- create the proper registry entries

The path is `HKEY_LOCAL_MACHINE\Software\JavaSoft`

## Another workaround

Start Exaplus direct with a java command. For further executions create an icon for the call.  

Example:

```shell
"c:\Program Files\Java\openJDK8\bin\java.exe" -jar "c:\Program Files (x86)\EXASOL\EXASolution-6.0\EXAplus\exaplusgui.jar"
```

## Additional References

* [CHANGELOG: EXAplus on Windows will use Java from the current console](https://exasol.my.site.com/s/article/Changelog-content-18724?language=en_US)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
