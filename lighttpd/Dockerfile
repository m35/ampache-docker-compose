FROM alpine:3.8

# https://git.alpinelinux.org/cgit/aports/tree/main/lighttpd/APKBUILD
RUN apk update && \
    apk add --no-cache \
            build-base \
            flex \
            pcre-dev \
            libressl-dev \
            zlib-dev \
            bzip2-dev \
            lua5.3-dev \
            automake \
            autoconf \
            openldap-dev \
            libxml2-dev \
            sqlite-dev \
            libev-dev \
            gamin-dev \
            # shadow for usermod/groupmod
            shadow

COPY lighttpd-1.4.50.tar.gz /

RUN gzip -cd lighttpd-1.4.50.tar.gz | tar fx -
WORKDIR /lighttpd-1.4.50
RUN	./configure \
		# --build=$CBUILD \
		# --host=$CHOST \
		--prefix=/usr \
		--disable-dependency-tracking \
		--enable-lfs \
		--libdir=/usr/lib/lighttpd \
		--without-mysql \
		--without-attr \
		--without-krb5 \
		--with-fam \
		--with-webdav-props \
		--with-webdav-locks \
		--without-gdbm \
		--with-bzip2 \
		--with-ldap \
		--with-openssl \
		--with-libev \
		--with-lua
RUN make check install
WORKDIR /
RUN mkdir -p /etc/lighttpd
RUN mv /lighttpd-1.4.50/doc/config/conf.d/* /etc/lighttpd

# https://github.com/docker-library/php/blob/master/5.6/alpine3.8/fpm/Dockerfile#L32
# Alpine Linux sets xfs:xfs UID=33 GID=33
# It also sets www-data:www-data UID=82 GID=82
# But we want to be compatible with Debian that has www-data:www-data as UID=33 GID=33
# So we'll swap them

# (When able to install from apk) need to swap the ids before installing lighttpd because it adds www-data GID=82
RUN usermod -u 82 xfs
RUN groupmod -g 82 xfs
RUN find / -user 33 -exec chown -h 82 {} \;
RUN find / -group 33 -exec chgrp -h 82 {} \;

RUN addgroup -g 33 -S www-data
RUN adduser -u 33 -D -S -G www-data www-data

# https://git.alpinelinux.org/cgit/aports/tree/main/lighttpd/lighttpd.pre-install
RUN addgroup -S lighttpd
RUN adduser -S -D -H -h /var/www/localhost/htdocs -s /sbin/nologin -G lighttpd -g lighttpd lighttpd
RUN addgroup lighttpd www-data

COPY lighttpd-start.sh /
RUN chmod 755 /lighttpd-start.sh

COPY ./lighttpd.conf /etc/lighttpd/lighttpd.conf

RUN chmod 755 /etc/lighttpd
RUN chmod -R 754 /etc/lighttpd/*
RUN chmod 755 /usr/lib/lighttpd
RUN chmod -R 754 /usr/lib/lighttpd/*

# Not going to clean up the mess we made getting here until everything is working right

# Expose http(s) ports
EXPOSE 80

# "The server has to be started as root to take control of port 80"
#USER lighttpd

ENTRYPOINT ["/lighttpd-start.sh"]
