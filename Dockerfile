# syntax=docker/dockerfile:1
# Imagem base TBDC: PHP 8.4 (FPM) + Phalcon 5 + nginx + supervisord.
# Usada por php-api, timeline e reports-php. Contém só o que é comum e demorado de instalar;
# configs (php.ini, nginx, supervisord) e código ficam em cada projeto.

ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-fpm-bookworm

ARG PHALCON_VERSION=5.23.0

LABEL org.opencontainers.image.title="php-phalcon" \
      org.opencontainers.image.description="PHP-FPM + Phalcon + nginx + supervisord (base TBDC)" \
      org.opencontainers.image.source="https://github.com/jesselopespereira/php-phalcon-base"

COPY --from=ghcr.io/mlocati/php-extension-installer:2 /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# locales: setlocale()/strftime() em pt_BR, es_ES e en_US (timeline e reports-php).
# gd: spipu/html2pdf (reports-php). exif: exif_read_data() (reports-php).
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends nginx supervisor unzip locales; \
    sed -i -E 's/^# *((pt_BR|es_ES|en_US)\.UTF-8 UTF-8)/\1/' /etc/locale.gen; \
    locale-gen; \
    install-php-extensions opcache pdo_mysql zip gd exif "phalcon-${PHALCON_VERSION}"; \
    rm -f /etc/nginx/sites-enabled/default; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Falha o build se alguma extensão não carregou.
RUN set -eux; \
    for ext in phalcon pdo_mysql zip gd exif; do php -m | grep -qix "$ext"; done; \
    php -m | grep -qi "zend opcache"; \
    php -r 'echo "PHP ", PHP_VERSION, " / Phalcon ", phpversion("phalcon"), PHP_EOL;'

WORKDIR /var/www/html
