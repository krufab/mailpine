CREATE DATABASE roundcubemail CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER 'roundcube'@'172.0.0.0/255.0.0.0' IDENTIFIED BY @password_roundcube@;
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'172.0.0.0/255.0.0.0';

CREATE DATABASE postfix CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER 'postfix'@'172.0.0.0/255.0.0.0' IDENTIFIED BY @password_postfix@;
GRANT ALL PRIVILEGES ON postfix.* TO 'postfix'@'172.0.0.0/255.0.0.0';
CREATE USER 'postfixadmin'@'172.0.0.0/255.0.0.0' IDENTIFIED BY @password_postfixadmin@;
GRANT ALL PRIVILEGES ON postfix.* TO 'postfixadmin'@'172.0.0.0/255.0.0.0';
CREATE USER 'dovecot'@'172.0.0.0/255.0.0.0' IDENTIFIED BY @password_dovecot@;
GRANT ALL PRIVILEGES ON postfix.* TO 'dovecot'@'172.0.0.0/255.0.0.0';

CREATE DATABASE phpmyadmin CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER 'pma'@'172.0.0.0/255.0.0.0' IDENTIFIED BY @password_pma@;
GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'172.0.0.0/255.0.0.0';

CREATE USER 'roundcube'@'%' IDENTIFIED BY @password_roundcube@;
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'%';
CREATE USER 'postfix'@'%' IDENTIFIED BY @password_postfix@;
GRANT ALL PRIVILEGES ON postfix.* TO 'postfix'@'%';
CREATE USER 'postfixadmin'@'%' IDENTIFIED BY @password_postfixadmin@;
GRANT ALL PRIVILEGES ON postfix.* TO 'postfixadmin'@'%';
CREATE USER 'dovecot'@'%' IDENTIFIED BY @password_dovecot@;
GRANT ALL PRIVILEGES ON postfix.* TO 'dovecot'@'%';
CREATE USER 'pma'@'%' IDENTIFIED BY @password_pma@;
GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'%';

/*
CREATE USER 'roundcube'@'192.168.0.0/255.255.0.0' IDENTIFIED BY @password_roundcube@;
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'192.168.0.0/255.255.0.0';
CREATE USER 'postfix'@'192.168.0.0/255.255.0.0' IDENTIFIED BY @password_postfix@;
GRANT ALL PRIVILEGES ON postfix.* TO 'postfix'@'192.168.0.0/255.255.0.0';
CREATE USER 'postfixadmin'@'192.168.0.0/255.255.0.0' IDENTIFIED BY @password_postfixadmin@;
GRANT ALL PRIVILEGES ON postfix.* TO 'postfixadmin'@'192.168.0.0/255.255.0.0';
CREATE USER 'dovecot'@'192.168.0.0/255.255.0.0' IDENTIFIED BY @password_dovecot@;
GRANT ALL PRIVILEGES ON postfix.* TO 'dovecot'@'192.168.0.0/255.255.0.0';
CREATE USER 'pma'@'192.168.0.0/255.255.0.0' IDENTIFIED BY @password_pma@;
GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'192.168.0.0/255.255.0.0';
*/
FLUSH PRIVILEGES;
