#!/bin/bash

if [ -f /run/httpd.pid ]; then
    rm -rf /run/httpd.pid
fi

/usr/sbin/start_apache2 -D SYSTEMD -DFOREGROUND -DSSL -k start
