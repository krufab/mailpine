## Configuration description

|Field|Type|Default|Description|
|-----|----|-------|-----------|
|**config.**|Object|||
|acmesh||||
|acmesh.account_email|String|Empty|The email to use with acme.sh|
|acmesh.debug|Boolean|false|true to debug acme.sh output|
|acmesh.default_dns_challenge|String|Empty|Parameters for acme.sh dns challenge|
|acmesh.dns_renew|Boolean|true|???|
|acmesh.enabled|Boolean|true|Enable certificate retrieval with acme.sh|
|acmesh.force|Boolean|false|true to force certificate generation|
|acmesh.keylength|String|4096|??? letsencrypt|
|acmesh.keylength-ec|String|ec-384|??? letsencrypt keys |
|acmesh.staging|Boolean|false|true to use letsencrypt staging server|
|docker||||
|docker.prefix|Sreing|mp_|prefix to use with docker compose|
|folders||||
|folders.backup|String|./backup|backup folder|
|folders.data|String|./data|data folder|
|folders.extra|String|./extra|extra folder|
|folders.log|String|./log|log folder|
|timezone|String|Europe/Luxembourg|The default timezone|
|verbosity_level|Integer|0|Increase verbosity (0,1,2)|
|-|-|-|-|
|**domains.**|Array|||
|domain|String||The main mail domain (example.com)|
|mail|String|imap|The subdomain for the email server (imap.example.com)|
|smtp|String|smtp|The subdomain for incoming email (smtp.example.com)|
|domain|String||Secondary domains for email|
|mail|String|imap||
|smtp|String|smtp||