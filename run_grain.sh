#!/bin/bash

set -e

CURRENT_VERSION="1.1"

cp -r /etc/service /tmp
test -d /var/log || cp -r /var_original/log /var
test -d /var/lib || cp -r /var_original/lib /var
test -d /var/run || cp -r /var_original/run /var
test -e /var/lock || ln -s /var/run/lock /var/lock
test -d /var/db || (mkdir /var/db && echo $CURRENT_VERSION > /var/VERSION)

test -e /var/VERSION || echo "1.0" > /var/VERSION
[[ "$(cat /var/VERSION)" == "${CURRENT_VERSION}" ]] || (cd /opt/app && echo "Upgrading Database...." && ./bin/update.sh && echo $CURRENT_VERSION > /var/VERSION)


mkdir -p /var/mail
touch /var/mail/dovecot-uidlist /var/mail/dovecot-uidvalidity /var/mail/dovecot.index.log
mkdir -p /var/log/roundcube/ /var/tmp
rm -rf /var/run/dovecot

exec /sbin/my_init
