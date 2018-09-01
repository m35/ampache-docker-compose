#!/bin/sh
set -e

# lighttpd will only accept an IP address for the fastcgi host
# Here we convert a host name PHP_FASTCGI_HOST to its equivalent IP address
# Then give that to lighttpd via environment variable PHP_FASTCGI_IP
if [ -z "${PHP_FASTCGI_HOST}" ]; then
    echo "PHP_FASTCGI_HOST must be set to the php fastcgi host"
    exit 1
fi

echo "The see the php fastcgi host PHP_FASTCGI_HOST = '${PHP_FASTCGI_HOST}'"
echo "Querying the IP address of '${PHP_FASTCGI_HOST}'"

export PHP_FASTCGI_IP=$(getent hosts ${PHP_FASTCGI_HOST} | awk '{ print $1 }')

if [ -z "${PHP_FASTCGI_IP}" ]; then
    echo "Could not find the IP address of '${PHP_FASTCGI_HOST}'"
    exit 1
fi

echo "Found the IP address of fastcgi host '${PHP_FASTCGI_HOST}' = ${PHP_FASTCGI_IP}"

# For debugging
#tail -f /dev/null

exec /usr/sbin/lighttpd -D -m /usr/lib/lighttpd -f /etc/lighttpd/lighttpd.conf "$@"
