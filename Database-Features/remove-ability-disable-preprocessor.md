# How to Remove the Ability to Disable PreProcessor Scripts

## Question
Notes on preprocessor suggest that users can read AND disable them (for local session).   For anything system critical, this vulnerability would be unacceptable.  Virtual schemas are interesting but can't handle queries across schemas, where meta-query governance is required. 

Is there a work-around?

Preprocessor Scripts explained - Exasol

    While often preprocessor scripts are enabled on system level, any user can disable this in his or her session (see (2) below)
    Preprocessor scripts are executed in the caller's context and privileges. Also, if user can EXECUTE the script (which is a necessity), he/she can also READ it. Security by obscurity won't work.


## Answer
There is a way: 

You can set the parameter alterSystemProhibitsAlterSessionForPreprocessing to 1, preventing users (other than SYS) from altering the use of the session/system-wide preprocessor script. 

You can add this parameter into Exaoperation:

-alterSystemProhibitsAlterSessionForPreprocessing=1  

You can find more about editing a database here: https://docs.exasol.com/administration/on-premise/manage_database/edit_database.htm

The preprocessor script will return an error if a query uses a prohibited back-end resources. This would still work within the preprocessor because queries within a preprocessor script are not subject to the preprocessor itself.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 