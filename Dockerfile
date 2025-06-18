ARG PHP_VERSION='8.2'
ARG BUILD_MODE="with-config"
FROM ulysse699/composer:latest AS vendors-installation

ARG COMPOSER_AUTH=""

ENV \
COMPOSER_ALLOW_SUPERUSER="1" \
COMPOSER_ALLOW_XDEBUG="0" \
COMPOSER_CACHE_DIR="/var/cache/composer" \
COMPOSER_AUTH="${COMPOSER_AUTH}"

VOLUME ["/var/cache/composer"]

COPY .composer /var/cache/composer

COPY src /src

RUN set -eux; \
composer install \
--prefer-dist \
--no-autoloader \
--no-interaction \
--no-scripts \
--no-progress \
--no-dev; \
composer dump-autoload \
--optimize

FROM ulysse699/app-php:latest as magento-with-vendors

USER root

RUN apt-get update
RUN apt-get install xxd
RUN apt-get install -y cron
RUN apt-get install -y vim

COPY --chown=rootless:rootless src /var/www

COPY --chown=rootless:rootless --from=vendors-installation src/vendor /var/www/vendor

COPY --chown=rootless:rootless system /

RUN set -eux; \
echo "/docker/d-bootstrap-magento.sh" >> /docker/d-bootstrap.list; \
chmod +x /docker/d-bootstrap-magento.sh

USER rootless
