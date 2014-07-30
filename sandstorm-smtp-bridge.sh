#!/bin/sh

while [ ! -e /tmp/sandstorm-api ]
do
  sleep 1
done

echo 'starting sandstorm-smtp-bridge'
/opt/app/sandstorm-smtp-bridge/bin/test-smtp 2>&1
