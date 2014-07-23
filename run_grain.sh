#!/bin/bash

set -e

cp -r /etc/service /tmp
test -d /var/log || cp -r /var_original/log /var
test -d /var/lib || cp -r /var_original/lib /var
test -d /var/run || cp -r /var_original/run /var
test -e /var/lock || ln -s /var/run/lock /var/lock
test -d /var/opt || (mkdir /var/opt && cp -r /opt/app /var/opt/app)
test -d /var/db || mkdir /var/db

mkdir -p /var/mail
touch /var/mail/dovecot-uidlist /var/mail/dovecot-uidvalidity /var/mail/dovecot.index.log
mkdir -p /var/log/roundcube/ /var/tmp
rm -rf /var/run/dovecot

exec /sbin/my_init
