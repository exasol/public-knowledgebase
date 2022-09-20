# Python: Module Not Found 
## Scope

When creating Python UDF's, you may depend on external libraries to accomplish some tasks. When these libraries are not installed by default, the UDF's will return an error stating that the module is not found. This article will describe how you solve this problem.

## Diagnosis

If the Python library you are trying to import is not installed by default, you will receive an error message like this:


```markup
[Code: 0, SQL State: 22002]  VM error: F-UDF-CL-LIB-1125: F-UDF-CL-SL-PYTHON-1000: F-UDF-CL-SL-PYTHON-1017: ExaUDFError: F-UDF-CL-SL-PYTHON-1122: Exception while parsing UDF  <UDF name>:1 <module> ImportError: No module named <module name>  (Session: 1690055142405898240)
```
## Explanation

Exasol's script languages are built using a set of default packages that are commonly used in Python applications. However, these are by no means exhaustive, and it is not possible to prepare for all possibilities. In regular Python environments, you can use pip install to add additional packages, but this command is not available within the Exasol database. You can use the below script to see exactly which packages are available for you to use.


```markup
--/ CREATE OR REPLACE PYTHON3 SCALAR SCRIPT "GET_AVAILABLE_PYTHON_MODULES" () EMITS ("res" VARCHAR(4096) UTF8) AS import pkgutil as pkgutil  def run(ctx):    for module_name in pkgutil.iter_modules():     ctx.emit(module_name[1]) /
```
 **Note: If using Python 2, just replace the PYTHON3 with PYTHON in the script definition.**

## Recommendation

To solve this problem, you can create a new Script Language Container. Before creating the container, you will add the requested packages to the flavors/<flavor>/flavor_customization/packages directory. The basic steps to create a Container look like this:

1. Clone the Github Repository
2. Choose your starting flavor. In most cases, you can take the "standard" flavor that corresponds to the database version you are using (example: standard-exasol-7.0.0.tar.gz). You can find the full list of flavors in the [/flavors/ folder in Github](https://github.com/exasol/script-languages-release/tree/master/flavors).
3. Navigate to the flavors/<flavor name>/flavor_customization/packages and edit either the python3_pip_packages or python2_pip_packages file (depending on which version Python you are using). Add the name(s) of the packages you need.
4. [Build the script language container using exaslct](https://github.com/exasol/script-languages-release#how-to-customize-an-existing-flavor)
5. Upload the container into BucketFS
6. Run an ALTER SESSION or ALTER SYSTEM statement to change which container is being used for UDF's.

**Note: You can use the exaslct command to automatically upload the built container into BucketFS and to generate the ALTER SESSION statement needed by running the following command:**


```markup
./exaslct upload --flavor-path=flavors/<flavor-name> --database-host <hostname-or-ip> --bucketfs-port <port> \                     --bucketfs-username w --bucketfs-password <password>  --bucketfs-name <bucketfs-name> \                    --bucket-name <bucket-name> --path-in-bucket <path/in/bucket>
```
You can find more in-depth instructions in the [Readme](https://github.com/exasol/script-languages-release#table-of-contents) of the Github Repository

## Additional References

* [Script Langauges in Github](https://github.com/exasol/script-languages-release)
* [Script Languages Documentation](https://docs.exasol.com/database_concepts/udf_scripts/adding_new_packages_script_languages.htm)
