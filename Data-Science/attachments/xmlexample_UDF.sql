create or replace java scalar script processXML(xml varchar(2000000)) 
emits (id int, name varchar(200000)) as
%scriptclass com.exasol.xmlexample.ProcessXML;

%jar /buckets/bucketfs1/jars/xmlexample-0.0.1-SNAPSHOT-jar-with-dependencies.jar;
/
commit;
-- Usage: SELECT
select processXML(v) from xmlparsing.myxml;

-- Usage: INSERT INTO ... FROM SELECT
create table cities (id int, name varchar(200000));
insert into cities select processXML(v) from xmlparsing.myxml;
commit;

select * from cities;

