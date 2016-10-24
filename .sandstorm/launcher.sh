#!/bin/bash

GID=`id -g`

CURRENT_VERSION="1.1"
test -d /var/db || (mkdir /var/db && echo $CURRENT_VERSION > /var/VERSION)

test -e /var/VERSION || echo "1.0" > /var/VERSION
[[ "$(cat /var/VERSION)" == "${CURRENT_VERSION}" ]] || (cd /opt/app && echo "Upgrading Database...." && ./bin/update.sh && echo $CURRENT_VERSION > /var/VERSION)

# Create a bunch of folders under the clean /var that php, nginx, and mysql expect to exist
mkdir -p /var/lib/nginx
mkdir -p /var/lib/dovecot
mkdir -p /var/lib/php5/sessions
mkdir -p /var/log
mkdir -p /var/log/nginx

mkdir -p /var/log/dovecot
mkdir -p /var/db /var/mail/cur /var/mail/new /var/mail/tmp /var/log/roundcube /var/tmp
touch /var/mail/dovecot-uidlist /var/mail/dovecot-uidvalidity /var/mail/dovecot.index.log

cp /opt/app/passwd /var
echo "user:x:$UID:$GID:user:/var:/bin/bash" >> /var/passwd

echo "user:{plain}pass:$UID:$GID::/var::userdb_mail=maildir:/var/mail" > /var/imap.passwd

# Wipe /var/run, since pidfiles and socket files from previous launches should go away
# TODO someday: I'd prefer a tmpfs for these.
rm -rf /var/run
mkdir -p /var/run/dovecot/login
chmod -R 777 /var/run/dovecot # for some awful reason, dovecot needs this to be world readable

/usr/sbin/dovecot 2>&1
sleep 3 # give dovecot just a bit of time to start up

/usr/sbin/php5-fpm --nodaemonize --fpm-config /etc/php5/fpm/php-fpm.conf &
# Wait until mysql and php have bound their sockets, indicating readiness
while [ ! -e /var/run/php5-fpm.sock ] ; do
    echo "waiting for php5-fpm to be available at /var/run/php5-fpm.sock"
    sleep .2
done

bash /opt/app/sandstorm-smtp-bridge.sh &

# Start nginx.
/usr/sbin/nginx -g "daemon off;"
