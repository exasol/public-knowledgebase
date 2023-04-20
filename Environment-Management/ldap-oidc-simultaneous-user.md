# Can a User Authenticate Using OIDC and LDAP Simultaneously?

## Question
Can the same user authenticate against an identity service using LDAP (from Tableau Desktop) and OIDC (from homegrown systems) simultaneously?

Or would I need to create 2 users with the same rights in the database? 

## Answer
I think it is only possible to have one user using one authentication method (username/pw, LDAP, Kerberos, or OIDC). So you would probably need to have two users (with different names) using different authentication methods and grant them the same roles/privileges.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 