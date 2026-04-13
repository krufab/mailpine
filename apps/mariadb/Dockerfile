FROM mariadb:11.4

RUN ln -fs /usr/share/zoneinfo/Europe/Luxembourg /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata
