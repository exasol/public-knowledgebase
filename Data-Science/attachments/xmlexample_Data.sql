create schema xmlparsing;

create or replace table myXML (v varchar(2000000));

insert into myXML values 
'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<document>     
     <entry>
          <id>1</id>
          <name>Nuremberg</name>
     </entry>
     <entry>
          <id>2</id>
          <name>Berlin</name>
     </entry>
</document>';

insert into myXML values 
'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<document>     
     <entry>
          <id>3</id>
          <name>London</name>
     </entry>
     <entry>
          <id>4</id>
          <name>Stockholm</name>
     </entry>
</document>';

commit;