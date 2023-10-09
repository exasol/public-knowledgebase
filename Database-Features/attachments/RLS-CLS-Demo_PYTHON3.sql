-- Preparation: Cleanup
impersonate sys;
drop schema if exists OUR_BANK cascade;
DROP FORCE VIRTUAL SCHEMA if exists SECURED_BANK cascade;

DROP TABLE IF EXISTS ADAPTER_SCHEMA.RESTRICTIONS_COLUMNS;
DROP TABLE IF EXISTS ADAPTER_SCHEMA.RESTRICTIONS_ROWS;

drop role if exists CLS_BALANCE_SECURED;
drop role if exists CLS_DETAILS_SECURED;
drop role if exists RLS_INSTITUTE_1;
drop role if exists IMP;

drop user if exists "MONICA";
drop user if exists "STEVE";
drop user if exists "JAKE";
drop user if exists "JESSICA";


-- Preparation: Setup
-- user management
create user "MONICA" identified by "a";
create user "STEVE" identified by "a";
create user "JAKE" identified by "a";

grant create session to MONICA;
grant create session to STEVE;
grant create session to JAKE;


-- impersonation (only for demo purposes)
create role IMP;
grant IMP to MONICA;
grant IMP to STEVE;
grant IMP to JAKE;

grant impersonation on MONICA to IMP;
grant impersonation on STEVE to IMP;
grant impersonation on JAKE to IMP;
grant impersonation on SYS to IMP;

-- load data
CREATE SCHEMA OUR_BANK;

CREATE OR REPLACE TABLE OUR_BANK.CUSTOMER (
    ID           DECIMAL(18,0),
    FIRST_NAME   VARCHAR(100) UTF8,
    LAST_NAME    VARCHAR(100) UTF8,
    EMAIL        VARCHAR(100) UTF8,
    GENDER       VARCHAR(10) UTF8,
    BALANCE      DECIMAL(8,2),
    CREDIT_SCORE DECIMAL(3,1),
    IBAN         VARCHAR(50) UTF8,
    INSTITUTE    VARCHAR(20) UTF8,
    SECURED      BOOLEAN
);


import into OUR_BANK.CUSTOMER from local csv file 'C:\path\to\RLS-CLS-data_schema_customer.csv' 
COLUMN SEPARATOR='|' skip=1;


create or replace table our_bank.customer as 
SELECT ID, FIRST_NAME, LAST_NAME, EMAIL, GENDER, BALANCE, CREDIT_SCORE, IBAN, INSTITUTE, case when institute = 'institute_1' then false else true end as secured
FROM OUR_BANK.CUSTOMER;






-- *******************************************************************
-- 	Show security features to secure sensitive data  -------
--          Now:         Row / Column Level Security
-- *******************************************************************



select * from OUR_BANK.CUSTOMER;

---------------------------
--       Meta setup     ---
---------------------------


-- create Adapter

CREATE SCHEMA IF NOT EXISTS ADAPTER_SCHEMA;


--/
CREATE OR REPLACE PYTHON3 ADAPTER SCRIPT ADAPTER_SCHEMA."RLS_ADAPTER" AS
import json

# For this example, we only support the data types VARCHAR, BOOLEAN, DECIMAL in the wrapped tables
def get_datatype(name, maxsize, prec, scale):
    if name.startswith("VARCHAR"):
        return {"type":"VARCHAR", "size":maxsize}
    if name == "BOOLEAN":
        return {"type":"BOOLEAN"}
    if name.startswith("DECIMAL"):
        return {"type":"DECIMAL", "precision":prec, "scale":scale}
    if name.startswith("CHAR"):
        return {"type":"CHAR", "size":maxsize}
    raise ValueError("Datatype '"+name+"' yet not supported in RLS virtual schema")    

# This function reads all the meta data for all the tables in the wrapped schema
def get_meta_for_schema(cn, s):
    import pyexasol
    c = exa.get_connection(cn)

    tabs = []
    with pyexasol.connect(dsn=c.address, user=c.user, password=c.password, protocol_version=pyexasol.PROTOCOL_V3) as conn:
        stmt = conn.meta.execute_meta_nosql("getTables", {"schema": s})
        if stmt.rowcount() == 0: raise ValueError('Config error: Can not create adapter for empty schema')
        for row in stmt:
            tabs.append(row["NAME"])

        rtabs = []
        for t in tabs:
            stmt =  conn.meta.execute_meta_nosql("getColumns", {"schema": s, "table": t})
            cols=[]
            for row in stmt:
                cols.append({"name":row["NAME"], "dataType": get_datatype(row["TYPE"],row["MAXSIZE"],row["NUM_PREC"],row["NUM_SCALE"])})
            rtabs.append({"name":t, "columns": cols})
        return rtabs

# This function gets the user restrictions regarding rows
def user_is_restricted(username,cn,t):
    import pyexasol
    c = exa.get_connection(cn)

    with pyexasol.connect(dsn=c.address, user=c.user, password=c.password, protocol_version=pyexasol.PROTOCOL_V3) as conn:
        with conn.execute("/*snapshot execution*/select distinct restricted from ADAPTER_SCHEMA.RESTRICTIONS_ROWS WHERE USERNAME IN(select granted_role from EXA_DBA_ROLE_PRIVS connect by grantee= PRIOR granted_role start with grantee='"+username+"') OR username='"+username+"' AND TABLENAME='"+t+"'") as stmt:
            if stmt.rowcount() == 0: return bool(0)
            if stmt.rowcount() > 1: raise ValueError('Config error: conflicting restrictions for user '+username+' in adapter_schema.RESTRICTIONS_ROWS')
            return bool(1)


# this function returns the restricted columns for a table
def get_restricted_columns_for_table(cn, s, tbl, u):
    import pyexasol
    c = exa.get_connection(cn)
    
    with pyexasol.connect(dsn=c.address, user=c.user, password=c.password, protocol_version=pyexasol.PROTOCOL_V3) as conn:
        with conn.execute("/*snapshot execution*/SELECT distinct columnname from adapter_schema.RESTRICTIONS_COLUMNS where username in (select granted_role from EXA_DBA_ROLE_PRIVS connect by grantee= PRIOR granted_role start with grantee='"+u+"') or username='"+u+"' and tablename='"+tbl+"'") as stmt:
            res = []
            if stmt.rowcount() > 0:
                for row in stmt:
                    res.append("'"+row[0]+"'")
                return ','.join(res)
            else: return None

# this function returns the projection attributes for a table including masking
def get_columns_for_table(cn, s, tbl, u):
    import pyexasol
    c = exa.get_connection(cn)
    l = get_restricted_columns_for_table(cn,s,tbl,u)
    with pyexasol.connect(dsn=c.address, user=c.user, password=c.password, protocol_version=pyexasol.PROTOCOL_V3) as conn:
        if l is not None: stmt = conn.meta.execute_snapshot("select case when column_name  in ("+l+") then '''***''' else column_name end as column_name from EXA_ALL_COLUMNS where column_schema='"+s+"' and column_table='"+tbl+"'")
        else: stmt = conn.meta.execute_snapshot("select column_name from EXA_ALL_COLUMNS where column_schema='"+s+"' and column_table='"+tbl+"'")
        cols = []
        for row in stmt:
            cols.append(row["COLUMN_NAME"])
        return ','.join(cols)


# This function implements the virtual schema adapter callback
def adapter_call(request):
    root = json.loads(request)
    if root["type"] == "createVirtualSchema":
        if not "properties" in root["schemaMetadataInfo"]: raise ValueError('Config error: required properties: "TABLE_SCHEMA" and "META_CONNECTION" not given')
        if not "TABLE_SCHEMA" in root["schemaMetadataInfo"]["properties"]: raise ValueError('Config error: required property "TABLE_SCHEMA" not given')
        if not "META_CONNECTION" in root["schemaMetadataInfo"]["properties"]: raise ValueError('Config error: required property "META_CONNECTION" not given')
        sn = root["schemaMetadataInfo"]["properties"]["TABLE_SCHEMA"]
        cn = root["schemaMetadataInfo"]["properties"]["META_CONNECTION"]
        res = {
            "type": "createVirtualSchema",
            "schemaMetadata": {"tables":get_meta_for_schema(cn, sn)}
        }
        return json.dumps(res)
    elif root["type"] == "dropVirtualSchema":
        return json.dumps({"type": "dropVirtualSchema"})
    elif root["type"] == "setProperties":
        return json.dumps({"type": "setProperties"})
    elif root["type"] == "refresh":
        sn = root["schemaMetadataInfo"]["properties"]["TABLE_SCHEMA"]
        cn = root["schemaMetadataInfo"]["properties"]["META_CONNECTION"]
        return json.dumps({"type": "refresh",
                           "schemaMetadata": {"tables":get_meta_for_schema(cn, sn)}})
    if root["type"] == "getCapabilities":
        return json.dumps({
            "type": "getCapabilities",
            "capabilities": []
            })
    elif root["type"] == "pushdown":
        req = root["pushdownRequest"]
        if req["type"] != "select": raise ValueError('Unsupported pushdown type: '+req["type"])
        from_ = req["from"]
        if from_["type"] != "table": raise ValueError('Unsupported pushdown from: '+from_["type"])
        table_ = from_["name"]
        row_filter = ""
        column_filter = get_columns_for_table(root["schemaMetadataInfo"]["properties"]["META_CONNECTION"],root["schemaMetadataInfo"]["properties"]["TABLE_SCHEMA"],table_,exa.meta.current_user) 
        if user_is_restricted(exa.meta.current_user,root["schemaMetadataInfo"]["properties"]["META_CONNECTION"],table_):
            row_filter = " WHERE secured=False"
        res = {
            "type": "pushdown",
            "sql": "SELECT "+column_filter+" FROM "+root["schemaMetadataInfo"]["properties"]["TABLE_SCHEMA"]+"."+table_+row_filter
        }
        return json.dumps(res)
    else:
        raise ValueError('Unsupported callback')
/

--create connection
create or replace connection SELF_CONNECTION to 'ws://localhost:8563' user 'SYS' identified by 'exasol';

-- create the virtual schema using the defined adapter and specified data schema
CREATE VIRTUAL SCHEMA SECURED_BANK USING adapter_schema.rls_adapter with table_schema='OUR_BANK' META_CONNECTION='SELF_CONNECTION';









------------------------------
--- Set role restrictions ---
------------------------------

-- role management
create role CLS_BALANCE_SECURED;  -- COLUMN LEVEL SECURITY on BALANCE
create role CLS_DETAILS_SECURED;  -- COLUMN LEVEL SECURITY on IBAN and CRETIT_SCORE
create role RLS_INSTITUTE_1;  -- ROW LEVEL SECURITY on INSTITUTE_1

-- restrict ROWS
CREATE OR REPLACE TABLE ADAPTER_SCHEMA.RESTRICTIONS_ROWS (
    USERNAME   VARCHAR(100) UTF8,
    RESTRICTED BOOLEAN,
    TABLENAME  VARCHAR(100) UTF8
);
INSERT INTO ADAPTER_SCHEMA.RESTRICTIONS_ROWS VALUES ('RLS_INSTITUTE_1',TRUE, 'CUSTOMER');

select * from ADAPTER_SCHEMA.RESTRICTIONS_ROWS;



-- restrict COLUMNS
CREATE TABLE ADAPTER_SCHEMA.RESTRICTIONS_COLUMNS (
    USERNAME   VARCHAR(100) UTF8,
    TABLENAME  VARCHAR(100) UTF8,
    COLUMNNAME VARCHAR(100) UTF8
);

INSERT INTO ADAPTER_SCHEMA.RESTRICTIONS_COLUMNS VALUES ('CLS_BALANCE_SECURED','CUSTOMER', 'BALANCE');
INSERT INTO ADAPTER_SCHEMA.RESTRICTIONS_COLUMNS VALUES  ('CLS_DETAILS_SECURED','CUSTOMER','IBAN');
INSERT INTO ADAPTER_SCHEMA.RESTRICTIONS_COLUMNS VALUES  ('CLS_DETAILS_SECURED','CUSTOMER','BALANCE');
INSERT INTO ADAPTER_SCHEMA.RESTRICTIONS_COLUMNS VALUES  ('CLS_DETAILS_SECURED','CUSTOMER','CREDIT_SCORE');

select * from adapter_schema.RESTRICTIONS_COLUMNS;











-------------------------------
--- Enable access for users ---
-------------------------------

-- Monica
grant CLS_BALANCE_SECURED to MONICA;

-- Steve
grant CLS_BALANCE_SECURED to STEVE;
grant RLS_INSTITUTE_1 to STEVE;

-- Jake
grant CLS_DETAILS_SECURED to JAKE;

-- grant access rights for users only to the virtual schema and not the data schema
grant select on SECURED_BANK to MONICA;
grant select on SECURED_BANK to STEVE;
grant select on SECURED_BANK to JAKE;







-----------------
-- Try it out
-----------------

-- Regional manager
impersonate MONICA;
select current_user;
select count(*) from SECURED_BANK.customer;
select * from SECURED_BANK.customer
where last_name like 'St%';

-- Institute_1
impersonate STEVE;
select count(*) from SECURED_BANK.customer;
select * from SECURED_BANK.customer
where last_name like 'St%';


-- IT Department
impersonate JAKE;
select count(*) from SECURED_BANK.customer;
select * from SECURED_BANK.customer
where last_name like 'St%';













-----------------
-- new Intern
-----------------
impersonate SYS;
create user "JESSICA" identified by "my_password";
grant create session to JESSICA;

-- setup RLS and CLS
grant RLS_INSTITUTE_1 to JESSICA;
grant CLS_DETAILS_SECURED to JESSICA;

grant select on SECURED_BANK to JESSICA;


-- impersonation (only for demo purposes)
grant impersonation on JESSICA to IMP;
grant IMP to JESSICA;

-- Try it out
impersonate JESSICA;
select count(*) from SECURED_BANK.customer;
select * from SECURED_BANK.customer 
where last_name like 'St%'
;













-----------------
-- new Regulations: Hide email
-----------------
impersonate SYS;
INSERT INTO ADAPTER_SCHEMA.RESTRICTIONS_COLUMNS VALUES  ('CLS_DETAILS_SECURED','CUSTOMER','EMAIL');
select * from ADAPTER_SCHEMA.RESTRICTIONS_COLUMNS;


impersonate JESSICA;
select * from SECURED_BANK.customer 
where last_name like 'St%'
;



















-----------------
-- Row- Column level security: easy to use!
-----------------

impersonate STEVE;

select count(*) from SECURED_BANK.customer;
select * from SECURED_BANK.customer
;

-- Search customer he just talked to
select * 
from SECURED_BANK.customer
where last_name like 'St%'
;

-- Target customers for next campaign
select * from SECURED_BANK.customer
where credit_score > 5 
and gender  = 'Male'
;























