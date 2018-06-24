FROM php:5.6-apache-stretch

LABEL maintainer="andrey.mikhalchuk@conceptant.com"
LABEL version="0.0.1.2"
LABEL description="This Dockerfile builds BIND9 with namemanager web UI"
LABEL "com.conceptant.vendor"="Conceptant, Inc."

ENV MYSQL_NM_PASSWORD "n9p7zD7DC3Xn2BQg"

ENV NM_API_URL "http://localhost:8090"
ENV NM_API_SERVER_NAME "localhost"

RUN apt-get update \
    && apt-get install -y \
        bzip2 \
        bind9 \
        mariadb-server \
        mariadb-client \
        wget \
        cron \
        inetutils-syslogd \
        libxml2-dev \
        vim \
        dnsutils

RUN wget https://repos.jethrocarr.com/pub/jethrocarr/source/namedmanager/namedmanager-1.8.0.tar.bz2 \
    && tar xjvf namedmanager-1.8.0.tar.bz2 \
    && rm namedmanager-1.8.0.tar.bz2 \
    && ln -s namedmanager-1.8.0 namedmanager \
    && mkdir -p /etc/namedmanager \
    && mkdir -p /var/www/html/namedmanager/etc_bind/ \
    && touch /var/log/cron.log

COPY files/namedmanager-config.php /etc/namedmanager/config.php
COPY files/bind-config.php /etc/namedmanager/config-bind.php
COPY files/namedmanager-bind.cron /etc/cron.d/namedmanager_bind
COPY files/namedmanager_logpush.rcsysinit /etc/init.d/namedmanager_logpush
COPY files/001-namedmanager.conf /etc/apache2/sites-available/
COPY files/php.ini /usr/local/etc/php/
COPY files/phpinfo.php /var/www/html/namedmanager/htdocs/
COPY files/docker-namedmanager-entrypoint /usr/local/bin
COPY files/etc_bind/ /var/www/html/namedmanager/etc_bind/

RUN docker-php-ext-install -j$(nproc) mysql \
    && docker-php-ext-install -j$(nproc) soap

RUN ln -s /etc/apache2/sites-available/001-namedmanager.conf /etc/apache2/sites-enabled/001-namedmanager.conf \
    && ln -s /etc/namedmanager/config.php $PWD/namedmanager/htdocs/include/config-settings.php \
    && ln -s /etc/namedmanager/config-bind.php $PWD/namedmanager/bind/include/config-settings.php \
    && sed -i -- "s#@NM_API_URL@#${NM_API_URL}#g" /etc/namedmanager/config-bind.php \
    && sed -i -- "s/@NM_API_SERVER_NAME@/${NM_API_SERVER_NAME}/g" /etc/namedmanager/config-bind.php \
    && chmod +x /etc/init.d/namedmanager_logpush /usr/local/bin/docker-namedmanager-entrypoint \
    && echo "LANG=en_US.UTF-8" > /etc/default/locale

VOLUME /var/log /var/lib/mysql /etc/bind

EXPOSE 8090 53/udp

ENTRYPOINT ["/usr/local/bin/docker-namedmanager-entrypoint"]
