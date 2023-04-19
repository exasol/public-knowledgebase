# LDAP Anonymous Connection

## Question
I have read the documentation about authenticating database users with LDAP: 

https://docs.exasol.com/sql/create_user.htm

I couldn't see any technical user for exasol configured here, so I assume that exasol is making an anonymous LDAP connection to ask for user authentication.

Is that true?

If yes, is there a way to configure the LDAP connection with a technical user instead of having it anonymous?

Follow-up: when Exasol uses internally the ldap_sasl_bind_s call to ask LDAP about the provided user credentials, is the communication between the application Exasol and the application LDAP anonymous or is Exasol communicating with its technical user and its credentials, e.g. as admin? 

## Answer
Exasol uses internally the ldap_sasl_bind_s call with the provided user credentials to authenticate the login user.  

Exasol is communicating with credentials given by the user which tries to login. For example if you have user_1:

> CREATE USER user_1 IDENTIFIED AT LDAP AS 'cn=user_1,dc=authorization,dc=exasol,dc=com';

In order to login into Exasol DB the user_1 have to use its ldap password, ie.

> exaplus -u user_1 -P <ldap_password_for_user_1>

Exasol then knows that user_1 should be authenticated using the configured ldap server and makes the call:

> ldap_sasl_bind_s(LDAP, "cn=user_1,dc=authorization,dc=exasol,dc=com", LDAP_SASL_SIMPLE, ldap_password_for_user_1, ...);

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 