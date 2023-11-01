# Send an EMAIL from Lua script 
## Background

The solution described below uses the 'socket' package.

Detailed documentation on the package can be found here: <http://w3.impa.br/~diego/software/luasocket/smtp.html>

No further installation is needed since 'socket' is part of Exasol's distribution.

## Solution using a Lua Script


```lua
--/
CREATE LUA SCRIPT "SEND_MAIL" ()
RETURNS ROWCOUNT AS

  smtp = require('socket.smtp')

  sender = 'service@exasol.com'
  receivers = { 'captain.exasol@exasol.com' } -- use a dictionary
  message_text = 'hello world'
	
  -- put the message contents into a dictionary:  
  mesgt = {
    -- SMTP headers
    headers = {
      to = 'Captain EXASOL <captain.exasol@exasol.com>',
      from = 'EXASOL Service <service@exasol.com>',
      subject = 'The mail you requested'
    },
    -- message body
    body = message_text
  }
	
  -- send mail using an SMTP server
  res, err = smtp.send{
    from = sender,
    rcpt = receivers, 
    source = smtp.message(mesgt),
    -- you have to know/ask for the correct mail server, our cluster does not know any.
    -- if the cluster has no DNS service, you need to use an IP address
    server = 'mail.exasol.com'
  }

  if err then
    error(err)
  end
/
```
## Additional Notes

### Ideas / Extensions

Provide Parameters for all parts of a mail like

* receiver(s)
* subject
* text

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 