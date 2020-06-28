<?php
  $CONF['configured'] = true;

  $CONF['setup_password'] = getenv('POSTFIXADMIN_SETUP_PASSWORD');

  $CONF['database_type'] = getenv('POSTFIXADMIN_DB_TYPE');
  $CONF['database_host'] = getenv('POSTFIXADMIN_DB_HOST');
  $CONF['database_port'] = 3306;
  $CONF['database_user'] = getenv('POSTFIXADMIN_DB_USER');
  $CONF['database_password'] = getenv('POSTFIXADMIN_DB_PASSWORD');
  $CONF['database_name'] = getenv('POSTFIXADMIN_DB_NAME');
//  $CONF['database_socket'] = '/var/run/mysqld/mysqld.sock';

// Site Admin
// Define the Site Admin's email address below.
// This will be used to send emails from to create mailboxes and
// from Send Email / Broadcast message pages.
// Leave blank to send email from the logged-in Admin's Email address.
$CONF['admin_email'] = '';
// Define the smtp password for admin_email.
// This will be used to send emails from to create mailboxes and
// from Send Email / Broadcast message pages.
// Leave blank to send emails without authentication
$CONF['admin_smtp_password'] = '';
// Site admin name
// This will be used as signature in notification messages
$CONF['admin_name'] = 'Postmaster';

// Mail Server
// Hostname (FQDN) of your mail server.
// This is used to send email to Postfix in order to create mailboxes.
$CONF['smtp_server'] = getenv('POSTFIXADMIN_SMTP_SERVER');
$CONF['smtp_port'] = getenv('POSTFIXADMIN_SMTP_PORT');

// SMTP Client
// Hostname (FQDN) of the server hosting Postfix Admin
// Used in the HELO when sending emails from Postfix Admin
$CONF['smtp_client'] = getenv('POSTFIXADMIN_SMTP_CLIENT');

// Set 'YES' to use TLS when sending emails.
$CONF['smtp_sendmail_tls'] = 'YES';

$CONF['encrypt'] = 'md5crypt';

$CONF['default_aliases'] = array (
    'abuse' => 'abuse@' . getenv('MP_DOMAIN'),
    'hostmaster' => 'hostmaster@' . getenv('MP_DOMAIN'),
    'postmaster' => 'postmaster@' . getenv('MP_DOMAIN'),
    'webmaster' => 'webmaster@' . getenv('MP_DOMAIN')
);

// Footer
// Below information will be on all pages.
// If you don't want the footer information to appear set this to 'NO'.
$CONF['show_footer_text'] = 'YES';
$CONF['footer_text'] = 'Return to ' . getenv('MP_FQDN_POSTFIXADMIN');
$CONF['footer_link'] = 'https://' . getenv('MP_FQDN_POSTFIXADMIN');
