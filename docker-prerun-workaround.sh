#!/bin/sh

# Start cron in the background
echo "Starting cron to cleanup library every night"
cron

# Start a process to watch for changes in the library with inotify
echo "Starting inotify to watch for changes in the library"
(
while true; do
    inotifywatch /media
    php /var/www/bin/catalog_update.inc -a
    sleep 30
done
) &
