#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx php5-fpm php5-cli php5-curl git php5-dev
# Install php
apt-get -y install php5-sqlite

# Install dovecot
apt-get -y install dovecot-imapd

# Install sandstorm-smtp-bridge
apt-get -y install build-essential
apt-get -y install git subversion autotools-dev automake autoconf libtool clang-3.4
ln -s /usr/bin/clang-3.4 /usr/bin/clang
ln -s /usr/bin/clang++-3.4 /usr/bin/clang++
export CXX=clang++
cd /tmp && git clone https://github.com/kentonv/capnproto.git && cd capnproto/c++ && ./setup-autotools.sh && autoreconf -i && ./configure && make clean && make -j2 check && make install
unset CXX
apt-get -y install libgpgme11-dev libgmime-2.6-dev libselinux1-dev

unlink /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/sandstorm-php <<EOF
server {
    listen 8000 default_server;
    listen [::]:8000 default_server ipv6only=on;

    server_name localhost;
    root /opt/app;
    location / {
        index index.php;
        try_files \$uri \$uri/ =404;
    }
    location ~ \\.php\$ {
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_split_path_info ^(.+\\.php)(/.+)\$;
        fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
ln -s /etc/nginx/sites-available/sandstorm-php /etc/nginx/sites-enabled/sandstorm-php
service nginx stop
service php5-fpm stop
systemctl disable nginx
systemctl disable php5-fpm
# patch /etc/php5/fpm/pool.d/www.conf to not change uid/gid to www-data
sed --in-place='' \
        --expression='s/^listen.owner = www-data/#listen.owner = www-data/' \
        --expression='s/^listen.group = www-data/#listen.group = www-data/' \
        --expression='s/^user = www-data/#user = www-data/' \
        --expression='s/^group = www-data/#group = www-data/' \
        /etc/php5/fpm/pool.d/www.conf
# patch /etc/php5/fpm/php-fpm.conf to not have a pidfile
sed --in-place='' \
        --expression='s/^pid =/#pid =/' \
        /etc/php5/fpm/php-fpm.conf
# patch nginx conf to not bother trying to setuid, since we're not root
# also patch errors to go to stderr, and logs nowhere.
sed --in-place='' \
        --expression 's/^user www-data/#user www-data/' \
        --expression 's#^pid /run/nginx.pid#pid /var/run/nginx.pid#' \
        --expression 's/^\s*error_log.*/error_log stderr;/' \
        --expression 's/^\s*access_log.*/access_log off;/' \
        /etc/nginx/nginx.conf
# Add a conf snippet providing what sandstorm-http-bridge says the protocol is as var fe_https
cat > /etc/nginx/conf.d/50sandstorm.conf << EOF
    # Trust the sandstorm-http-bridge's X-Forwarded-Proto.
    map \$http_x_forwarded_proto \$fe_https {
        default "";
        https on;
    }
EOF
# Adjust fastcgi_params to use the patched fe_https
sed --in-place='' \
        --expression 's/^fastcgi_param *HTTPS.*$/fastcgi_param  HTTPS               \$fe_https if_not_empty;/' \
        /etc/nginx/fastcgi_params

mkdir -p /var/db /var/mail/cur /var/mail/new /var/mail/tmp /var/log/roundcube /var/tmp
chmod 777 /var/db
cat > /etc/dovecot/conf.d/auth-system.conf.ext <<EOF
passdb {
  driver = passwd-file
  args = scheme=plain username_format=%n /etc/imap.passwd
}
userdb {
  driver = passwd-file
  args = username_format=%n /etc/imap.passwd
}
EOF

cat >> /etc/dovecot/dovecot.conf <<EOF
service anvil {
  chroot =
}
service imap-login {
  chroot =
  inet_listener imap {
    port = 10143
  }
  inet_listener imaps {
    port = 10993
  }
}
default_internal_user = user
default_login_user = user
EOF
echo 'user:{plain}pass:1000:1000::/var::userdb_mail=maildir:/var/mail' > /etc/imap.passwd
echo 'user:x:1000:1000:user:/var:/bin/bash' >> /etc/passwd
