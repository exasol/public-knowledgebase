# How to Block Users from Seeing All Roles

## Question
Users can currently see more senior or other roles than they have been granted.  Is this is a feature or a bug?

## Answer
This is as designed but we have a preprocessor which can help.

It searches for the tables EXA_ALL_ROLES and EXA_ALL_TABLES within the SQL text sent by the user, and if it detects these strings, then it will check if the user has the SELECT ANY DICTIONARY privilege (which lets users see every statistics/sys table and is also granted to DBA) as a role.

When a user who doesn't have SELECT ANY DICTIONARY runs SELECT * FROM EXA_ALL_ROLES, they get this error message which you can customize.

[Code: 0, SQL State: 43100] While preprocessing SQL with "ALLSCRIPTS"."PP_HIDE_TABLES": 43000:"You must be a DBA or have SELECT ANY DICTIONARY to run this query" caught in script "ALLSCRIPTS"."PP_HIDE_TABLES" at line 18 (Session: 1673753318205978533)

This is an extremely simple script and would need to be expanded for other cases/tables/roles, etc)
```
--/
CREATE OR REPLACE LUA SCRIPT "ALLSCRIPTS"."PP_HIDE_TABLES" () RETURNS ROWCOUNT AS
    sql_text = sqlparsing.getsqltext()
    sql_text = string.upper(sql_text)
    tokens = sqlparsing.tokenize(sql_text)
    
        disallowed_table_names = {'EXA_ALL_ROLES','EXA_ALL_USERS'}
        for i=1, #disallowed_table_names do
                matched_name = sqlparsing.find(tokens,1,true,true,sqlparsing.iswhitespaceorcomment,disallowed_table_names[i])

                if matched_name ~= nil then
                        string_found = true
                        for i=1, #matched_name do
                                --if a match is found, check if they have SELECT ANY DICTIONARY
                                if sqlparsing.isidentifier(tokens[matched_name[i]]) then
                                        res = query([[SELECT * FROM EXA_ROLE_SYS_PRIVS WHERE PRIVILEGE = 'SELECT ANY DICTIONARY' UNION ALL SELECT * FROM EXA_USER_SYS_PRIVS WHERE PRIVILEGE = 'SELECT ANY DICTIONARY';]])
                                        if #res == 0 then
                                                -- User does not have SELECT ANY DICTIONARY privilege - throws error
                                                output([[error]])
                                                error([[You must be a DBA or have SELECT ANY DICTIONARY to run this query]])
                                        end
                
                                                
                                else
                                        output([[No identifier]])
                                        --sqlparsing.setsqltext(sql_text)       
                                
                                end
                                        
                                
                        end
                        
                
                end
        end
        output(sql_text)
        sqlparsing.setsqltext(sql_text)   
        
/

alter system set sql_preprocessor_script = "ALLSCRIPTS"."PP_HIDE_TABLES";
```