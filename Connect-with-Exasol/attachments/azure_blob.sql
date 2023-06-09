-- set define off; -- command only needed if you use EXAplus
-- drop schema azure_blob cascade;
create schema azure_blob;
-- open schema azure_blob;

--/
create or replace python scalar script blob_connection_helper() returns boolean as
import site
from azure.storage.blob import BlockBlobService

account_name = 'exa'
sas_token = 'sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14'
blob_service = BlockBlobService(account_name=account_name, sas_token=sas_token)
/

---------------------------------------------------------------------------
-- READ FROM AZURE BLOB
-- the example imports some public test data from the big data benchmark:
-- https://amplab.cs.berkeley.edu/benchmark/
---------------------------------------------------------------------------

create or replace table
	rankings(
		pageurl varchar(300),
		pagerank int,
		avgduration int
	);

--/
create or replace python scalar script blob_generate_urls(container_name varchar(1024), folder_name varchar(1024)) emits (url varchar(4096)) as
blob_service = exa.import_script('blob_connection_helper').blob_service

def run(ctx):
	list = blob_service.list_blobs(ctx.container_name, prefix=ctx.folder_name)
	for blob in list:
	    #print blob.name
	    protocol, filepath = blob_service.make_blob_url(ctx.container_name, blob.name, sas_token=blob_service.sas_token).split('://', 1)
	    ctx.emit(filepath)
/

--/
create or replace lua script blob_parallel_read(table_name, container_name, folder_name) returns table as
	-- number of parallel files imported in one import statement:
	local par = 4
	local pre = "IMPORT INTO " .. table_name .. " FROM CSV AT 'https://'"
	local res = query([[
		select blob_generate_urls(:cn, :fn) order by 1
	]], {cn=container_name, fn=folder_name})
	local fin = {}
	local str = ''
	for i = 1, #res do
		if math.fmod(i,par) == 1 or par == 1 then
			str = pre
		end
		str = str .. "\n\tFILE '" .. res[i][1] .. "'"
		if (math.fmod(i,par) == 0 or i == #res) then
--			str = str .. " ENCODING='ASCII' SKIP=1 ERRORS INTO POC.IMPORT_ERRORS('" .. res[i][1] .. "') REJECT LIMIT UNLIMITED;"
--			str = str .. " ENCODING='ASCII' SKIP=1 REJECT LIMIT UNLIMITED;"
			str = str .. ";"
			table.insert(fin,{str})
		end
	end
	exit(fin, "queries varchar(2000000)")
/

-- let's read from a container called "test-csv"
execute script blob_parallel_read('azure_blob.rankings', 'test-csv', 'rankings/');
-- You can copy the result and execute it on the database, or you can enhance the script with query/pquery to run the statements on the database directly.
-- The result is something like:
/*
IMPORT INTO azure_blob.rankings FROM CSV AT 'https://'
	FILE 'exa.blob.core.windows.net/test-csv/rankings/part-00000?sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14'
	FILE 'exa.blob.core.windows.net/test-csv/rankings/part-00001?sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14'
	FILE 'exa.blob.core.windows.net/test-csv/rankings/part-00002?sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14'
	FILE 'exa.blob.core.windows.net/test-csv/rankings/part-00003?sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14';
IMPORT INTO azure_blob.rankings FROM CSV AT 'https://'
	FILE 'exa.blob.core.windows.net/test-csv/rankings/part-00004?sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14'
	FILE 'exa.blob.core.windows.net/test-csv/rankings/part-00005?sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14'
	FILE 'exa.blob.core.windows.net/test-csv/rankings/part-00006?sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14'
	FILE 'exa.blob.core.windows.net/test-csv/rankings/part-00007?sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14';
IMPORT INTO azure_blob.rankings FROM CSV AT 'https://'
	FILE 'exa.blob.core.windows.net/test-csv/rankings/part-00008?sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14'
	FILE 'exa.blob.core.windows.net/test-csv/rankings/part-00009?sr=c&si=exa-test-csv-readonly-unlimited&sig=wWM6OT9je2yFQ%2B6gR62OjwC48OCpdAQ9kMmbSPfBy%2Bc=&sv=2014-02-14';
*/