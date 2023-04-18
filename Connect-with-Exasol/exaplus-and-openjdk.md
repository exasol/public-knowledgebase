# EXAplus and openJDK 
## Problem

After openJDK was successfully installed EXAplus still won't start with an error message like


```
Can not find the Java Runtime Environment needed by EXAplus.  
Trying to use system wide virtual machine (from registry) instead.   
No 64 bit java virtual machine found in registry.
```
## Diagnosis

EXAplus requires a java runtime instance and proper registry entries to start

## Solution

#### 1. Verify openJDK installation

Execute command "java -version" on the command line

A possible output may look like


```
openjdk 11.0.2 2019-01-15  
OpenJDK Runtime Environment 18.9 (build 11.0.2+9)  
OpenJDK 64-Bit Server VM 18.9 (build 11.0.2+9, mixed mode)
```
The next step depends on what you downloaded, a JRE only or the complete JDK.

#### 2.

#### a) JDK

It comes with a MSI installer and works as any other windows installer and does the necessary registry entries.  
But EXAplus needs a JRE instance to start. Contrary to Oracles installation, there's no own "jre" folder  
in the installation path of the JDK. Just create one and copy all contents again to this folder and EXAplus  
should start.

#### 2.b) JRE

The JRE is only a ZIP file and doesn't edit registry during the unzip to the desired folder. You can edit the registry using the Registry Editor. [This article](https://www.howtogeek.com/school/using-windows-admin-tools-like-a-pro/lesson5/) describes some tips on doing this, or you can view Microsoft's documentation.

- edit existing registry entries manually  
- create the proper registry entries

The path is {{HKEY_LOCAL_MACHINE\Software\JavaSoft}}

## Another workaround

Start Exaplus direct with a java command. For further executions create an icon for the call.  
Example:
```
"c:\Program Files\Java\openJDK8\bin\java.exe" -jar "c:\Program Files (x86)\EXASOL\EXASolution-6.0\EXAplus\exaplusgui.jar"
```
