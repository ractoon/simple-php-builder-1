FROM php:7.4.16-fpm

RUN apt-get update && apt-get install -y \
        apt-utils \
        git \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libsqlite3-dev \
        libzip-dev \
        nginx \
        procps \
        supervisor \
        wget \
        zlib1g-dev \

    && docker-php-ext-install pdo_mysql pdo_sqlite mysqli gd json zip opcache \
    && EXPECTED_COMPOSER_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig) \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '${EXPECTED_COMPOSER_SIGNATURE}') { echo 'Composer.phar Installer verified'; } else { echo 'Composer.phar Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/usr/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

RUN apt-get update && \
    apt-get install -y gnupg && \
    curl -sL https://deb.nodesource.com/setup_12.x -o /nodesource_setup.sh && \
    chmod a+x /nodesource_setup.sh && \
    /nodesource_setup.sh && \
    apt-get install -y nodejs && \
    apt-get install -y libxml2-dev && \
    docker-php-ext-install soap && \
    apt-get install -y gconf-service libasound2 libatk1.0-0 libcairo2 libcups2 libfontconfig1 libgdk-pixbuf2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libxss1 fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils

RUN adduser --system --no-create-home --shell /bin/false --group --disabled-login nginx


RUN apt-get install -y zlib1g-dev libicu-dev g++ unzip && \
      docker-php-ext-install pcntl && \
      pecl install xdebug

RUN docker-php-ext-configure intl && \
    docker-php-ext-install intl

RUN apt install -y chromium
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/default.conf /etc/nginx/sites-enabled/default
COPY docker/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY --chmod=111 docker/start.sh /start.sh

EXPOSE 443 80
WORKDIR /code

ENV PATH=$PATH:/code/vendor/bin
ARG HTTP_ROOT=/code/apps/wildalaskancompany.com/public

RUN sed -i "s|{{HTTP_ROOT}}|${HTTP_ROOT}|g" /etc/nginx/sites-enabled/default

ENTRYPOINT ["/bin/bash", "-c", "/start.sh"]
