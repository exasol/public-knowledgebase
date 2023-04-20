# How to create DDL for Exasol support 
## Problem

 To reproduce certain problems, Exasol support may ask you to send DDL statements for required tables and views.  
At this point you have two choices:

1. Start drilling around to find each and every required view / table etc. This may be a lot of work and may end up with some communication round trips in case you overlooked a dependency or two.
2. Skip all that and just send us the full DDL for all schemas in your database instance. Just let us sort out what is needed and what is not.  
Both options are not optimal. 

## Solution

The attachment of this article contains a procedure script (Lua) that can create DDL statements for recursive dependencies of a view. The DDL are presented as a single-column result-set and are ready for copy/paste into a text editor (or EXAplus) for saving.

 ## Example Call

  **Script call**  
```"code-sql"
--DDL created by user SYS at 2017-11-14 09:44:59.554000

--========================================--
--           table dependencies           --
--========================================--
CREATE SCHEMA "DUT";
CREATE TABLE "DUT"."TAB1"(
	"I" DECIMAL(18,0) IDENTITY NOT NULL,
	"J" DECIMAL(3,0)
);
-- SYSTEM TABLE: SYS.EXA_METADATA



--========================================--
--         function dependencies         --
--========================================--
function func( param decimal(3) ) returns decimal(3)
as
begin
	return sqrt(param) * (select max(i) from dut.tab1);
end
/

--========================================--
--          script dependencies          --
--========================================--
CREATE LUA SCALAR SCRIPT "LUA_SCALAR" () RETURNS DECIMAL(18,0) AS
function run()
		return decimal(10,18,0)
	end

/

--========================================--
--           view dependencies           --
--========================================--

--> level 2
-- SYSTEM VIEW: SYS.CAT

--> level 1
CREATE VIEW "DUT"."BRANCH"
	as ( select * from exa_metadata, cat );

-- final query/view:
CREATE VIEW "DUT"."TRUNK"
	as (
		select * from dut.tab1, dut.branch
		where func(j) > lua_scalar()
	);
```
   ## Caution

 This script is work in progress and has only seen minimal testing so far.

## Things known not to work:

* Virtual Schemas – It is unlikely we would be able to clone your remote system anyway.
* Connections and IMPORT inside views – Like virtual schemas, it probably does not make much sense.
* Dependencies inside scripts – This is branded 'dynamic SQL' and our engine can not determine those dependencies without actually executing the script with specific input.
* SELECT dependencies inside functions – Just don't do that. Like with scripts, these dependencies to not show up in the system.

There are the following prerequisites to run the script:

* "SELECT ANY DICTIONARY" privilege to access some of data dictionary views.
* Access to all direct and indirect dependencies of the view.

If your model contains any of the above and it turns out to be relevant for reproduction of a problem, you might have to revert to "Skip all that" above. The "Copy Database" script in [create-ddl-for-the-entire-database](https://exasol.my.site.com/s/article/Create-DDL-for-the-entire-Database) may be of use then.

 ## Additional References

The script itself: [create_view_ddl.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/create_view_ddl.sql)

<https://www.exasol.com/support/browse/IDEA-359>

[create-ddl-for-the-entire-database](https://exasol.my.site.com/s/article/Create-DDL-for-the-entire-Database)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 