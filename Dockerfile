FROM php:7.4-apache

LABEL maintainer="Kitware, Inc. <cdash@public.kitware.com>"

RUN apt-get update                                                             \
 && apt-get dist-upgrade -y                                                    \
 && apt-get install -y gnupg                                                   \
 && curl -sL https://deb.nodesource.com/setup_10.x | bash                      \
 && apt-get install -y git libbz2-dev libfreetype6-dev libjpeg62-turbo-dev     \
    libmcrypt-dev libpng-dev libpq-dev libxslt-dev libxss1 nodejs unzip wget   \
    zip                                                                        \
 && docker-php-ext-configure pgsql --with-pgsql=/usr/local/pgsql               \
 && docker-php-ext-configure gd --with-freetype=/usr/include/              \
                                --with-jpeg=/usr/include/                  \
 && docker-php-ext-install -j$(nproc) bcmath bz2 gd pdo_mysql pdo_pgsql xsl    \
 && wget -q -O checksum https://composer.github.io/installer.sha384sum         \
 && wget -q -O composer-setup.php https://getcomposer.org/installer            \
 && sha384sum -c checksum                                                      \
 && php composer-setup.php --install-dir=/usr/local/bin --filename=composer    \
 && php -r "unlink('composer-setup.php');"                                     \
 && composer self-update --no-interaction

RUN mkdir -p /var/www/cdash
COPY php.ini /var/www/cdash/php.ini
COPY xml_handlers /var/www/cdash/xml_handlers
COPY app /var/www/cdash/app
COPY composer.lock /var/www/cdash/composer.lock
COPY public /var/www/cdash/public
COPY scripts /var/www/cdash/scripts
COPY sql /var/www/cdash/sql
COPY package.json /var/www/cdash/package.json
COPY .php_cs /var/www/cdash/.php_cs
COPY config /var/www/cdash/config
COPY log /var/www/cdash/log
COPY gulpfile.js /var/www/cdash/gulpfile.js
COPY backup /var/www/cdash/backup
COPY include /var/www/cdash/include
COPY bootstrap /var/www/cdash/bootstrap
COPY composer.json /var/www/cdash/composer.json
COPY scripts/bash /bash-lib

RUN cd /var/www/cdash                                                      \
 && composer install --no-interaction --no-progress --prefer-dist --no-dev \
 && npm install                                                            \
 && node_modules/.bin/gulp                                                 \
 && chmod 777 backup log public/rss public/upload                          \
 && rm -rf /var/www/html                                                   \
 && ln -s /var/www/cdash/public /var/www/html                              \
 && rm -rf composer.lock package.json gulpfile.js composer.json

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

WORKDIR /tmp
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US
ENV LC_ALL C
ENV SHELL /bin/bash
ENV BASH_ENV /etc/bash.bashrc
ENV DEBIAN_FRONTEND noninteractive
SHELL [ "/bin/bash", "--login", "-c" ]

COPY ./docker/cdash-cron.sh /etc/cron.d/cdash-cron.sh
COPY ./docker/authenticator.sh /var/www/cdash/
COPY ./docker/cleanup.sh /var/www/cdash/
COPY ./docker/run-maintenance.sh /var/www/cdash/
COPY ./docker/md5check.sh /etc/profile.d/
COPY ./docker/cdash.sh /etc/profile.d/

RUN echo mysql-apt-config mysql-apt-config/select-server select mysql-5.7 | debconf-set-selections && \
    wget -O mysql-apt-config.deb https://dev.mysql.com/get/mysql-apt-config_0.8.17-1_all.deb    && \
    md5check mysql-apt-config.deb 9e393c991311ead61dcc8313aab8e230                              && \
    dpkg -i mysql-apt-config.deb                                                                && \
    apt-get update                                                                              && \
    apt-get dist-upgrade -y                                                                     && \
    apt-get install -y mysql-client certbot python-certbot-apache cron emacs-nox                && \
    apt-get autoremove -y --purge                                                               && \
    apt-get autoclean                                                                           && \
    mkdir -p /var/lib/cdash-db-backup                                                           && \
    mkdir -p /var/www/cdash/.well-known/acme-challenge                                          && \
    chmod 744 /etc/cron.d/cdash-cron.sh                                                         && \
    chmod 755 /var/www/cdash/{authenticator,cleanup,run-maintenance}.sh                         && \
    crontab /etc/cron.d/cdash-cron.sh                                                           && \
    touch /var/log/cron.log                                                                     && \
    rm /tmp/mysql-apt-config.deb

WORKDIR /var/www/cdash
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5m \
  CMD ["curl", "-f", "http://localhost/viewProjects.php"]

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
CMD ["serve"]
