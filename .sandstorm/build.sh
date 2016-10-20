#!/bin/bash
# Checks if there's a composer.json, and if so, installs/runs composer.

set -euo pipefail

cd /opt/app

cp composer.json-dist composer.json
if [ -f /opt/app/composer.json ] ; then
    if [ ! -f composer.phar ] ; then
        curl -sS https://getcomposer.org/installer | php
    fi
    php composer.phar install
fi

cd /opt/app/sandstorm-smtp-bridge && make

cd /opt/app/sandstorm && make && sudo cp bin/* /usr/bin
