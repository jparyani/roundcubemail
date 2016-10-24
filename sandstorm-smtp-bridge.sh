#!/bin/sh

while [ ! -e /tmp/sandstorm-api ]
do
  sleep 1
done

sleep 5
echo 'starting sandstorm-smtp-bridge'
/opt/app/sandstorm-smtp-bridge/bin/sandstorm-smtp-bridge 2>&1
