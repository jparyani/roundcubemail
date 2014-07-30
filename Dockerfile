# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:0.9.11

# Set correct environment variables.
ENV HOME /root

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh
# Disable cron
RUN rm -rf /etc/service/cron

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN apt-get update

# Install php
RUN apt-get -y install php5 php5-sqlite

# Install nginx
RUN apt-get -y install php5-fpm nginx

# Install dovecot
RUN apt-get -y install dovecot-imapd

# Install sandstorm-smtp-bridge
RUN apt-get -y install build-essential
RUN apt-get -y install git subversion autotools-dev automake autoconf libtool clang-3.4
RUN cd /tmp && git clone https://github.com/kentonv/capnproto.git && cd capnproto/c++ && ./setup-autotools.sh && autoreconf -i && ./configure && make clean && make -j2 check && make install
RUN apt-get -y install libgpgme11-dev libgmime-2.6-dev libselinux1-dev

RUN mkdir /etc/service/dovecot
ADD dovecot.sh /etc/service/dovecot/run

RUN mkdir /etc/service/nginx
ADD nginx.sh /etc/service/nginx/run

RUN mkdir /etc/service/php
ADD php.sh /etc/service/php/run

RUN mkdir /etc/service/sandstorm-smtp-bridge
ADD sandstorm-smtp-bridge.sh /etc/service/sandstorm-smtp-bridge/run

# setup nginx
ADD nginx.conf /etc/nginx/nginx.conf
RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/php.ini
RUN sed -i 's_^listen\s*=\s*.*_listen = 127.0.0.1:9000_g' /etc/php5/fpm/pool.d/www.conf
RUN sed -i 's_^user\s*=\s*.*_user = 1000_g' /etc/php5/fpm/pool.d/www.conf
RUN sed -i 's_^group\s*=\s*.*_group = 1000_g' /etc/php5/fpm/pool.d/www.conf

# Setup dovecot
RUN mkdir -p /var/db /var/mail/cur /var/mail/new /var/mail/tmp /var/log/roundcube /var/tmp
RUN chmod 777 /var/db
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
# run `cp -r /opt/sandstorm/latest/usr/include/sandstorm sandstorm-headers` manually
ADD sandstorm-headers /opt/sandstorm/latest/usr/include/sandstorm
RUN cd /opt/app/sandstorm-smtp-bridge && make
RUN cd /opt/app/sandstorm && make && cp bin/* /usr/bin

EXPOSE 33411

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN rm -rf /usr/share/vim /usr/share/doc /usr/share/man /var/lib/dpkg /var/lib/belocs /var/lib/ucf /var/cache/debconf /var/log/*.log