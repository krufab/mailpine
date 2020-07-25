# Postfix

## Log info
http://postfix.org/postconf.5.html#maillog_file_prefixes
http://www.postfix.org/DEBUG_README.html
https://docs.iredmail.org/debug.postfix.html

## Email queue cleanup
https://www.cyberciti.biz/tips/howto-postfix-flush-mail-queue.html

### To see mail queue, enter:
`mailq`

`postqueue -p`

### Remove all emails
`postsuper -d ALL`

### Remove all emails in deferred queue
`postsuper -d ALL deferred`

### Remove Specific Email
`postqueue -p | grep "email@example.com"`

056CB129FF0*    5513 Sun Feb 26 02:26:27  email@example.com

Now delete the mail from mail queue with id 056CB129FF0.

`postsuper -d 056CB129FF0`

## Other email applications
https://mailcow.github.io/mailcow-dockerized-docs/prerequisite-system/
https://git.nilux.be/nilux/docker-mailserver