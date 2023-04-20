# Is PyExasol Encrypted?

## Question
My company has been switching from Teradata to Exasol and I am one of few working the database via Python. The question I have is about the Python driver PyExasol and how secure the connection is. With our Teradata Driver, all credentials were stored in two pre-encrypted key files that were handed over via a special connection syntax to the database for verification.  

From what I can see from in the Github documentation, this is not the case for PyExasol. It looks to me as if credentials have to be stored in a plain text file and the connection is completely unencrypted. This is less than ideal. 

From the following example:

https://github.com/exasol/pyexasol/blob/master/examples/15_encryption.py

it looks like encryption has to be set to TRUE, but if I do so, my database seems to refuse connection. Is the connection generally completely unencrypted? Do credentials get transferred in plain text?

I would be very grateful if anyone could shine some light on that matter. 

## Answer
The authorisation process in PyEXASOL is encrypted in all cases. Server sends public key which is used to encrypt a password. Password is never sent as plain text by design of WebSocket protocol.

You may find more details here: https://github.com/exasol/websocket-api/blob/master/docs/commands/loginV3.md

Also, you may add connection option "debug=True" for "pyexasol.connect()" and see JSON requests and responses.

"encryption=True" enables TLS encryption for all the communication happening after authorisation. Normally it does not require any extra setup. 

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 