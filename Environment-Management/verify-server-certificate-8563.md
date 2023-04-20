# How to Verify an Exasol Server Certificate Over 8563

## Question
Is there a straight-forward way for end-users to verify an exasol server certificate over 8563?

Using a web-browser, we can validate ExaSolution on 443 easily.

Is a certificate uploaded to Exasolution also propagated to the nodes for ODBC/JDBC connections?

## Answer
If you just want to verify the certificate without really connecting to the database: 

```
echo -n | openssl s_client -connect \<ip addr of one exasol node>:8563 
```

The end of the command output should look like this:
```
Key-Arg   : None  
PSK identity: None  
    PSK identity hint: None  
    SRP username: None  
    Start Time: 1633614216  
    Timeout   : 300 (sec)  
    Verify return code: 0 (ok)  
\---  
DONE
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 