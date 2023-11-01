# Access and Excel File through Python

## Question
I am trying to access an Excel file through Python, but the trustworthy `pandas.read_excel` doesn't seem to work (the `xlrd` library is missing).

Does anyone know of any other preinstalled python libraries that can read Excel files?

## Answer
If you want to process Excel files you will need external libraries. If you do not want to generate a language container you have two other options.

In each case you need to configure a bucket for your Exasol. But this task will take less than 5 minutes  ([Create New Buckets in BucketFS Service](https://docs.exasol.com/administration/on-premise/bucketfs/create_new_bucket_in_bucketfs_service.htm)). Make sure that you configure a read and write password for your bucket and that you add an HTTP port for your BucketFS Service. If the bucket is configured you can load all libraries which you need to solve your problem in wheel (`.whl`) format or `tar.gz` format and add them straight to the bucket. 

You can load it from this page: https://pypi.org/project/xlrd/ and add this file to the bucket using one of

* `curl`
* ["bucketfs-client" application](https://github.com/exasol/bucketfs-client/blob/main/doc/user_guide/user_guide.md)
* ["bucketfs-python" library](https://exasol.github.io/bucketfs-python/user_guide/user_guide.html)
* ["BucketFSExplorer" application](https://github.com/exasol/bucketfs-explorer)

If this is done you need to activate your uploaded file inside your UDF-Script and then you will be able to use the included functionality inside your UDF.

Inside your Bucket you can store `whl` and `tar.gz` file. For my tests I also uploaded two test files to process but for best practice those files (test) including data should not be loaded into the Bucket.

Here is a code example how I can acitvate both a wheel file or tar.gz file (there is a little difference in the syntax for the activation):

```python
CREATE or replace PYTHON3 SCALAR SCRIPT UDF_TEST.EXCEL_PROCESSING_TEST() EMITS ( "RES" VARCHAR(2000000) UTF8) AS  
import glob  
#--Syntax for activating a tar.gz file  
sys.path.extend(glob.glob('/buckets/bfsdefault/jsc/xlrd-1.2.0/*'))  
import xlrd  
#--Syntax for activating a wheel file  
sys.path.extend(glob.glob('/buckets/bfsdefault/jsc/xlrd-2.0.1-py2.py3-none-any.whl'))  
import pandas as pd  
import os  
def run(c):  
	fe = os.path.exists("/buckets/bfsdefault/jsc/test.xlsx")  
	df=pd.read_excel("/buckets/bfsdefault/jsc/test.xlsx",engine='xlrd')  
	c.emit("File exists: " + str(fe))  
	c.emit(str(df))  
	c.emit("Pandas Version: " + str( pd.__version__ ) )  
	c.emit("Xlrd Version: " + str( xlrd.__version__ ) )  
/

select UDF_TEST.EXCEL_PROCESSING_TEST() ;
```

In the result you can see that I am able to read the data from the xlsx into a Dataframe. This is the "quick win" how you can do this stuff inside the Exasol. But there will come another problem because you can only use versions from `xlrd` up to 1.2.0, all later version will no longer support xlsx format and you need to use other libraries like `openpyxl` (which will need a different `pandas` version than preinstalled - to be checked, as pandas was recently upgraded). But it would not be a problem to also add a different `pandas` version with a wheel file inside the bucket and the `openpyxl`, include them in your UDF and there you go.

But as mentioned before, the best solution for me would be the language container which was already mentioned earlier. You don´t need to think about library dependencies when using pip here and do not need to add multiple files. I totally agree reading through the git and testing all this stuff will need some time. For this we created a bash script which takes some input parameter and is a little easier to use to generate this script, move it to your Exasol Bucket and activate the new language container inside your DB automatically.

## Additional References

* [Create New Buckets in BucketFS Service](https://docs.exasol.com/administration/on-premise/bucketfs/create_new_bucket_in_bucketfs_service.htm)
* [User guide for "script-languages-release" github repo](https://github.com/exasol/script-languages-release/blob/master/doc/user_guide/usage.md)
* ["bucketfs-client" application](https://github.com/exasol/bucketfs-client/blob/main/doc/user_guide/user_guide.md)
* ["bucketfs-python" library](https://exasol.github.io/bucketfs-python/user_guide/user_guide.html)
* ["BucketFSExplorer" application](https://github.com/exasol/bucketfs-explorer)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 