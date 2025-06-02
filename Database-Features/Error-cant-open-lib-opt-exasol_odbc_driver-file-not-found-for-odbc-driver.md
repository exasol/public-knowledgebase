# Error "Can't open lib '/opt/exasol_odbc_driver' : file not found" for odbc driver

## Problem

As Exasol ODBC driver doesn't have / create symlinks itself when a new version of ODBC driver is installed, the user is used to create symlinks to driver libraries to avoid changing ODBC DSN definition, it's sufficient to update only the symlink.
After upgrading to ODBC driver 24.0.0 or later version, it gives below error

```text
Can't open lib '/opt/exasol_odbc_driver' : file not found
```

This change in behaviour is caused by  [Merge Exasol ODBC and SDK Packages](https://exasol.my.site.com/s/article/Changelog-content-18720?language=en_US)

## Solution

In Exasol ODBC Drivers prior to 24.0.0, ODBC and CLI were a single file. But now they are split to two different files. Exasol ODBC is dependent on Exasol CLI (located in lib/libexacli.so in the Exasol ODBC Package). It is mandatory that both files should be at same place even for the symlink. To confirm this the issue, you can run

```text
$> ldd exasol_odbc_driver
linux-vdso.so.1 (0x00007fd97b644000)
libresolv.so.2 => /lib64/libresolv.so.2 (0x00007fd97b611000)
libpthread.so.0 => /lib64/libpthread.so.0 (0x00007fd97b60c000)
libodbcinst.so => /lib64/libodbcinst.so (0x00007fd97b5f8000)
libexacli.so => not found
libstdc++.so.6 => /lib64/libstdc++.so.6 (0x00007fd97ae00000)
libm.so.6 => /lib64/libm.so.6 (0x00007fd97b510000)
libc.so.6 => /lib64/libc.so.6 (0x00007fd97ac0c000)
libgcc_s.so.1 => /lib64/libgcc_s.so.1 (0x00007fd97b4e1000)
libltdl.so.7 => /lib64/libltdl.so.7 (0x00007fd97b4d6000)
/lib64/ld-linux-x86-64.so.2 (0x00007fd97b646000)
```

If the above output is observed (i.e. libexacli.so => not found ). Then it is likely the above described behavior. If that's the case, create a symlink of the exacli too.

Again run the previous command to check the library is loaded properly (
libexacli.so => /home/testuser/libexacli.so (0x00007fb4d3600000) )

```text
ldd exasol_odbc_driver
linux-vdso.so.1 (0x00007fb4d45ac000)
libresolv.so.2 => /lib64/libresolv.so.2 (0x00007fb4d4579000)
libpthread.so.0 => /lib64/libpthread.so.0 (0x00007fb4d4574000)
libodbcinst.so => /lib64/libodbcinst.so (0x00007fb4d4560000)
libexacli.so => /home/testuser/libexacli.so (0x00007fb4d3600000)
libstdc++.so.6 => /lib64/libstdc++.so.6 (0x00007fb4d3200000)
libm.so.6 => /lib64/libm.so.6 (0x00007fb4d4478000)
libc.so.6 => /lib64/libc.so.6 (0x00007fb4d300c000)
libgcc_s.so.1 => /lib64/libgcc_s.so.1 (0x00007fb4d41d1000)
libltdl.so.7 => /lib64/libltdl.so.7 (0x00007fb4d41c6000)
/lib64/ld-linux-x86-64.so.2 (0x00007fb4d45ae000)
```

If the issue still persists, provide the output of the `ldd` command to Exasol Support.

### Additional references

* [Merge Exasol ODBC and SDK Packages](https://exasol.my.site.com/s/article/Changelog-content-18720?language=en_US)
