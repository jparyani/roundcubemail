# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:0.9.11

# Set correct environment variables.
ENV HOME /root

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN apt-get update

# Install php
RUN apt-get -y install php5 php5-sqlite

# Install nginx
RUN apt-get -y install php5-fpm nginx

# Install dovecot
RUN apt-get -y install dovecot-imapd

RUN apt-get -y install telnet

RUN mkdir /etc/service/dovecot
ADD dovecot.sh /etc/service/dovecot/run

RUN mkdir /etc/service/nginx
ADD nginx.sh /etc/service/nginx/run

RUN mkdir /etc/service/php
ADD php.sh /etc/service/php/run

# setup nginx
ADD nginx.conf /etc/nginx/nginx.conf
RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/php.ini

# Setup dovecot
RUN mkdir -p /var/db /var/mail/cur /var/mail/new /var/mail/tmp /var/log/roundcube /var/tmp
RUN echo 'passdb {\n\
  driver = passwd-file\n\
  args = scheme=plain username_format=%n /etc/imap.passwd\n\
}\n\
userdb {\n\
  driver = passwd-file\n\
  args = username_format=%n /etc/imap.passwd\n\
}' > /etc/dovecot/conf.d/auth-system.conf.ext
RUN echo 'service anvil {\n\
  chroot = \n\
}\n\
service imap-login {\n\
  chroot =\n\
  inet_listener imap {\n\
    port = 10143\n\
  }\n\
  inet_listener imaps {\n\
    port = 10993\n\
  }\n\
}\n\
default_internal_user = user\n\
default_login_user = user\n' >> /etc/dovecot/dovecot.conf
RUN echo 'user:{plain}pass:1000:1000::/var::userdb_mail=maildir:/var/mail' > /etc/imap.passwd
RUN echo 'user:x:1000:1000:user:/var:/bin/bash' >> /etc/passwd
RUN chmod -R 777 /var/mail

ADD . /opt/app
RUN rm -rf /opt/app/.git

EXPOSE 33411

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN rm -rf /usr/share/vim /usr/share/doc /usr/share/man /var/lib/dpkg /var/lib/belocs /var/lib/ucf /var/cache/debconf /var/log/*.log