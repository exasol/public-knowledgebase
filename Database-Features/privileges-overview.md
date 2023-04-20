# Privileges overview 
## Background

This solution describes how to determine all granted system and object privileges per user. 

## Explanation

The following SQL statement will return:

* PUBLIC privileges
* direct privileges
* object definitions
* system privileges


```"code
with all_granted_roles as (
	with k1 as (
		select
			grantee, granted_role,
			( select max(user_name) from exa_dba_users where user_name = grantee ) as user_name
		from EXA_DBA_ROLE_PRIVS rp
	
	union all
	
		select
			user_name, 'PUBLIC', user_name
		from exa_dba_users
	)
	select CONNECT_BY_ROOT(GRANTEE) grantee, GRANTED_ROLE
	from k1
	CONNECT BY GRANTEE = PRIOR GRANTED_ROLE
	start with user_name is not null
)

, all_object_privileges as (
	SELECT gr.GRANTEE as USER_NAME, gr.GRANTED_ROLE, op.PRIVILEGE, op.object_schema, op.object_name
	from all_granted_roles gr
	join SYS.EXA_DBA_OBJ_PRIVS op
	  on gr.GRANTED_ROLE = op.GRANTEE

	union all

	SELECT us.USER_NAME, null, op.PRIVILEGE, op.object_schema, op.object_name
	from SYS.EXA_DBA_USERS us
	join SYS.EXA_DBA_OBJ_PRIVS op
	  on us.USER_NAME = op.GRANTEE
)

, all_system_privileges as (
	SELECT gr.GRANTEE as user_name, gr.granted_role, op.PRIVILEGE
	from all_granted_roles gr
	join SYS.EXA_DBA_SYS_PRIVS op
	  on gr.GRANTED_ROLE = op.GRANTEE

	union all

	SELECT us.USER_NAME, null, op.PRIVILEGE
	from SYS.EXA_DBA_USERS us
	join SYS.EXA_DBA_SYS_PRIVS op
	  on us.USER_NAME = op.GRANTEE
)

select user_name, granted_role, privilege, object_schema, object_name
	from all_object_privileges
union all
select user_name, granted_role, privilege, null, null
	from all_system_privileges
;
```
If you get an error message, such as "CONNECT BY loop in user data", you may need to edit the SQL slightly:


```"code
with all_granted_roles as (
	with k1 as (
		select
			grantee, granted_role,
			( select max(user_name) from exa_dba_users where user_name = grantee ) as user_name
		from EXA_DBA_ROLE_PRIVS rp
	
	union all
	
		select
			user_name, 'PUBLIC', user_name
		from exa_dba_users
	)
	select CONNECT_BY_ROOT(GRANTEE) grantee, GRANTED_ROLE
	from k1
	CONNECT BY NOCYCLE GRANTEE = PRIOR GRANTED_ROLE
	start with user_name is not null
)
....
```
## Additional Information:

Here is the SQL to determine all granted system and object privileges per user and role:


```"code-java"
with all_granted_roles as (
	with k1 as (
		select
			grantee, granted_role,
			( select max(user_name) from exa_dba_users where user_name = grantee ) as user_name, 'none' owner_name
		 from EXA_DBA_ROLE_PRIVS rp
		
	union all
	
		select
			user_name, 'PUBLIC', user_name, 'none' owner_name
		from exa_dba_users
	
	) 
	
	select CONNECT_BY_ROOT(GRANTEE) grantee, GRANTED_ROLE, user_name as new_user_name, 'none' owner_name
	from k1
	CONNECT BY GRANTEE = PRIOR GRANTED_ROLE
	--start with user_name is not null
	
)
, all_object_privileges as (
	SELECT gr.GRANTEE as USER_NAME, gr.GRANTED_ROLE, op.PRIVILEGE, op.object_schema, op.object_name, 
	case when new_user_name is null then 'ROLE'  else 'USER' end as user_or_role, op.owner owner_name
	from all_granted_roles gr
	join SYS.EXA_DBA_OBJ_PRIVS op
	  on gr.GRANTED_ROLE = op.GRANTEE

	union all

	SELECT us.USER_NAME, null, op.PRIVILEGE, op.object_schema, op.object_name, 'USER' as user_or_role, 'none' owner_name
	from SYS.EXA_DBA_USERS us
	join SYS.EXA_DBA_OBJ_PRIVS op
	  on us.USER_NAME = op.GRANTEE
) 
, all_system_privileges as (
	SELECT gr.GRANTEE as user_name, gr.granted_role, op.PRIVILEGE , 
	case when new_user_name is null then 'ROLE'  else 'USER' end as user_or_role, 'none' owner_name
	from all_granted_roles gr
	join SYS.EXA_DBA_SYS_PRIVS op
	  on gr.GRANTED_ROLE = op.GRANTEE

	union all

	SELECT us.USER_NAME, null, op.PRIVILEGE, 'USER' as user_or_role , 'none' owner_name
	from SYS.EXA_DBA_USERS us
	join SYS.EXA_DBA_SYS_PRIVS op
	  on us.USER_NAME = op.GRANTEE
) 

select user_name user_name_or_role_name, granted_role, privilege, object_schema, object_name, user_or_role, owner_name
	from all_object_privileges
union all
select user_name user_name_or_role_name, granted_role, privilege, null, null, user_or_role, owner_name
	from all_system_privileges
;
```
## A note for complex role setups

On databases with thousands of roles (entries in table EXA_DBA_ROLE_PRIVS) the 'connect by (nocycle)' approach could lead to excessive use of TEMP_DB_RAM, long duration, or even an aborted statement.

The connect by query currently returns a row for each possible "grant-path". The connect by query will walk over each of those paths and the number can be **exponential**.

The same result could be obtained with a Lua UDF, which is really fast:  



```"lia-code-sample
CREATE OR REPLACE LUA SET SCRIPT compute_all_granted_roles_ext (grantee varchar(128)
,granted_role varchar(128)
,user_name varchar(128))
emits (grantee varchar(128), granted_role varchar(128)-- ) AS
      ,new_user_name varchar(128), owner_name varchar(128) ) AS
function run(ctx)
    -- granted maps a grantee to all their directly granted roles
    local granted = {}
    -- set of all users
    local users = {}

    repeat
        if ctx.user_name ~= null then
                users[ctx.user_name] = true
        end

        if granted[ctx.grantee] == nil then
                granted[ctx.grantee] = {}
        end
        table.insert(granted[ctx.grantee], ctx.granted_role)
    until not ctx.next()

    for current_user, _ in pairs(users) do
        local all_roles = {}

        local roles_to_check = {}
        table.insert(roles_to_check, current_user)

        while #roles_to_check > 0 do
            local current_role = table.remove(roles_to_check)

            if granted[current_role] ~= nil then
                for _, r in pairs(granted[current_role]) do
                    if all_roles[r] == nil then
                        all_roles[r] = true;
                        table.insert(roles_to_check, r)
                    end
                end
            end
        end

        for r, _ in pairs(all_roles) do
            ctx.emit(current_user, r, current_user, 'none')
--            ctx.emit(current_user, r)
        end
    end
end
/
```
The beginning of the SQL will now look like


```"lia-code-sample
with all_granted_roles as (
with k1 as (
  select grantee, granted_role,
	( select max(user_name) from exa_dba_users where user_name = grantee ) as user_name, 'none' owner_name
	 from EXA_DBA_ROLE_PRIVS rp

  union all
	
  select user_name, 'PUBLIC', user_name, 'none' owner_name
    from exa_dba_users
    ) 

 select COMPUTE_ALL_GRANTED_ROLES_EXT(GRANTEE, GRANTED_ROLE, USER_NAME)
  from k1
)
, all_object_privileges as (
...
```
## Additional References

<https://docs.exasol.com/database_concepts/privileges.htm>

<https://docs.exasol.com/sql/grant.htm>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 