<?php

/*
 +-----------------------------------------------------------------------+
 | Local configuration for the Roundcube Webmail installation.           |
 |                                                                       |
 | This is a sample configuration file only containing the minimum       |
 | setup required for a functional installation. Copy more options       |
 | from defaults.inc.php to this file to override the defaults.          |
 |                                                                       |
 | This file is part of the Roundcube Webmail client                     |
 | Copyright (C) The Roundcube Dev Team                                  |
 |                                                                       |
 | Licensed under the GNU General Public License version 3 or            |
 | any later version with exceptions for skins & plugins.                |
 | See the README file for a full license statement.                     |
 +-----------------------------------------------------------------------+
*/

$config = [];

// Database connection string (DSN) for read+write operations
// Format (compatible with PEAR MDB2): db_provider://user:password@host/database
// Currently supported db_providers: mysql, pgsql, sqlite
// For examples see http://pear.php.net/manual/en/package.database.mdb2.intro-dsn.php
// NOTE: for SQLite use absolute path (Linux): 'sqlite:////full/path/to/sqlite.db?mode=0646'
//       or (Windows): 'sqlite:///C:/full/path/to/sqlite.db'
//$config['db_dsnw'] = 'mysql://roundcube:password@unix(/var/run/mysqld/mysqld.sock)/roundcubemail';
$config['db_dsnw'] = 'mysql://' .
  getenv('ROUNDCUBEMAIL_DB_USER') . ':'. getenv('ROUNDCUBEMAIL_DB_PASSWORD') .
  '@' . getenv('ROUNDCUBEMAIL_DB_HOST') . ':' . getenv('ROUNDCUBEMAIL_DB_PORT') .
  '/' . getenv('ROUNDCUBEMAIL_DB_NAME');

// IMAP host chosen to perform the log-in.
// See defaults.inc.php for the option description.
$config['imap_host'] = getenv('ROUNDCUBEMAIL_DEFAULT_HOST') . ":" .  getenv('ROUNDCUBEMAIL_DEFAULT_PORT');

// IMAP authentication method (DIGEST-MD5, CRAM-MD5, LOGIN, PLAIN or null).
// Use 'IMAP' to authenticate with IMAP LOGIN command.
// By default the most secure method (from supported) will be selected.
$config['imap_auth_type'] = 'PLAIN';

// SMTP server host (for sending mails).
// See defaults.inc.php for the option description.
$config['smtp_host'] = getenv('ROUNDCUBEMAIL_SMTP_SERVER') . ":" . getenv('ROUNDCUBEMAIL_SMTP_PORT');

// SMTP username (if required) if you use %u as the username Roundcube
// will use the current username for login
$config['smtp_user'] = '%u';

// SMTP password (if required) if you use %p as the password Roundcube
// will use the current user's password for login
$config['smtp_pass'] = '%p';

// provide an URL where a user can get support for this Roundcube installation
// PLEASE DO NOT LINK TO THE ROUNDCUBE.NET WEBSITE HERE!
$config['support_url'] = '';

// Name your service. This is displayed on the login screen and in the window title
$config['product_name'] = 'Roundcube Webmail';

// This key is used to encrypt the users imap password which is stored
// in the session record. For the default cipher method it must be
// exactly 24 characters long.
// YOUR KEY MUST BE DIFFERENT THAN THE SAMPLE VALUE FOR SECURITY REASONS
$config['des_key'] = 'rcmail-!24ByteDESkey*Str';

// List of active plugins (in plugins/ directory)
$config['plugins'] = [
    'archive',
    'zipdownload',
];

// skin name: folder from skins/
$config['skin'] = 'elastic';
