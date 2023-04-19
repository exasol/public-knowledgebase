# How to load multiple small files from an FTP Server in parallel 
## Background

#### This solution focuses on loading lots of small files from an FTP server in parallel.

If you have CSV Files, you can just use our IMPORT to load these files in parallel


```"code-sql"
import into <targettable> from csv at my_connection file 'file1.csv' file 'file2.csv' file 'file3.csv' 
 at another_connection file 'file4.csv' file 'file5.csv'  --and so on... ; 
```
## Prerequisites

However, this approach requires that

1. You know the list of files to be imported and put those names into a single SQL statement
2. All the files share the same data structure.

If you have small files with a different format, that you either just want to store in a single varchar column or that you want to parse e.g. with another UDF, have a look at the following example:

## How to load multiple small files from an FTP server in parallel

## Step 1

First of all, you can get a list of all files within a directory by leaving the file empty for an IMPORT, using a subselect you can apply filters to the retrieved file list.


```"code-sql"
select right(c1, 36) as filename from 
 (     
  import into(c1 varchar(200)) from csv at 'ftp://192.168.1.1/UUID_FILES' user 'ftpuser' identified by 'password' FILE '' 
 ) 
 where c1 not like '%.' 
```
Please note that the data returned is the output of the FTP LIST command and may vary between different FTP server implementations.

## Step 2

The following python UDF connects to an FTP server (it can not use CONNECTION objects) and then reads all files passed as argument:


```"code-sql"
-- this script connects to an ftp and reads files. either the whole file is emitted or data is split on newlines
-- it is created as a set script to be able to load several files within one group to open only a single connection
create or replace python set script load_files_from_ftp
(ftp_user varchar(100), ftp_password varchar(100),ftp_url varchar(2000),port decimal(5), ftp_path varchar(100), filename varchar(100), split_on_newline boolean)
  emits(filename varchar(100), output_data VARCHAR(2000000)) as
from ftplib import FTP
def run(ctx):
	ftp = FTP()
	ftp.connect(ctx.ftp_url,ctx.port)
	ftp.login(ctx.ftp_user, ctx.ftp_password)
	while True:
		data=[]
		def handle_binary(more_data):
			data.append(more_data)
		resp = ftp.retrbinary("RETR "+ctx.ftp_path + ctx.filename,callback=handle_binary)
		if ctx.split_on_newline == True:
			lines = "".join(data).split('\n')
			for line in lines:
				if len(line) > 1:
					ctx.emit(ctx.filename,line)
		else:
			ctx.emit(ctx.filename, "".join(data))
		if not ctx.next():
			break		
/
```
## Step 3

Now let's put the pieces together. The "group by random(X)" defines the parallelity. This will result in at maximum X groups and these X groups will be loaded in parallel. Using this approach you can limit the number of parallel connections in order to control resource usage on your ftp-server.


```"code-sql"
select load_files_from_ftp('ftpuser','password','192.168.153.1', '21','/UUID_FILES/',filename,false) from 
(
	select right(c1, 36) as filename from
	(
		import into(c1 varchar(200)) from csv at ftp_connection FILE ''
	)
	where c1 not like '%.'
	order by filename
)
group by cast(random(1,10) as decimal)
;
```
Of course, you rarely want to get the result on the screen, but typically embed the select into an INSERT statement.

## Additional References

<https://docs.exasol.com/database_concepts/udf_scripts/python.htm>

<https://docs.exasol.com/sql/import.htm>

<https://docs.exasol.com/loading_data/other_file_formats.htm>

<https://docs.exasol.com/database_concepts/udf_scripts.htm>

