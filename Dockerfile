FROM php:5.6.37-fpm-stretch

LABEL maintainer="m35@users.noreply.github.com"

RUN apt-get update && \
    apt-get install -y \
        wget \
        inotify-tools \
        ffmpeg \
        file \
        nano \
        git \
        pwgen \
        lame \
        libvorbis-dev \
        vorbis-tools \
        flac \
        libmp3lame-dev \
        libavcodec-extra* \
        libtheora-dev \
        libvpx-dev \
        libav-tools \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev

# Install php extensions gd and pdo_mysql
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install gd \
    && docker-php-ext-install pdo_mysql

# Download and install composer for dependency management
RUN php -r "readfile('https://getcomposer.org/installer');" | php && \
    mv composer.phar /usr/local/bin/composer

# Option to install ampache in maybe a sub-dir
# That can ONLY be changed once and must be done the first time you run `Docker-compose up`.
# Incomplete support beacuse all lighttpd url references need to prepend the directory
# Maybe try a subdomain?
ARG AMPACHE_URL_PATH=/

# Download HEAD (master) version from Ampache
ADD https://github.com/ampache/ampache/archive/master.tar.gz /opt/ampache-master.tar.gz
# Extract
RUN tar -C /var/www${AMPACHE_URL_PATH} -xf /opt/ampache-master.tar.gz ampache-master --strip=1

# Own all the things
RUN chown -R www-data:www-data /var/www
RUN chmod -R 755 /var/www

# Run composer
# It's ok to run composer as root when building docker containers
ENV COMPOSER_ALLOW_SUPERUSER=1
# Running as chain so 'cd' doesn't mess thing up
# Best practices says "use WORKDIR instead of proliferating instructions like RUN cd ... && do-something"
# But how do you return to the prior WORKDIR??
RUN cd /var/www${AMPACHE_URL_PATH} && \
    composer install --prefer-source --no-interaction

# Make the ampache logging directory in case we need it
RUN mkdir -p /var/log/ampache/
RUN chown -R www-data:www-data /var/log/ampache
RUN chmod -R 755 /var/log/ampache
# Could also point ampache config to "$APACHE_LOG_DIR/error.log" and "$APACHE_LOG_DIR/access.log" which already point to stderr/stdout

# TODO also modify the php.ini settings to increase php max upload size, along with other good settings

# Add job to cron to clean the library every night
RUN echo '30 7    * * *   www-data php /var/www${AMPACHE_URL_PATH}/bin/catalog_update.inc' >> /etc/crontab

# Because Docker
RUN mv /usr/local/bin/docker-php-entrypoint /usr/local/bin/docker-php-entrypoint.original \
    && echo "#!/bin/sh" > /usr/local/bin/docker-php-entrypoint \
    && echo "set -e" >> /usr/local/bin/docker-php-entrypoint \
    && echo "docker-prerun-workaround.sh" >> /usr/local/bin/docker-php-entrypoint \
    && cat /usr/local/bin/docker-php-entrypoint.original >> /usr/local/bin/docker-php-entrypoint
COPY docker-prerun-workaround.sh /usr/local/bin/docker-prerun-workaround.sh
RUN chmod 755 /usr/local/bin/docker-prerun-workaround.sh
RUN chmod 755 /usr/local/bin/docker-php-entrypoint
