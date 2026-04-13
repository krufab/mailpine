To debug dovecot

in dovecot.conf

auth_verbose=yes
auth_debug=yes
auth_debug_passwords=yes
mail_debug=yes
verbose_ssl=yes
auth_verbose_passwords=plain

https://doc.dovecot.org/admin_manual/logging/