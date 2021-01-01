
FROM php:8.0.0-fpm-buster

RUN apt-get update; apt-get install -y wget net-tools vim curl \
    iputils-ping dnsutils procps libxml2-dev libzip-dev libwebp-dev \
    libpng-dev libxpm-dev libjpeg62-turbo-dev libfreetype6-dev \
    git bzip2 libbz2-dev zip unzip graphviz

RUN docker-php-source extract \
    && docker-php-ext-install bcmath bz2 sockets pdo_mysql mysqli \
    && docker-php-ext-install gd intl ctype zip

RUN git clone https://github.com/nikic/php-ast.git \
    && cd php-ast \
    && phpize \
    && ./configure \
    && make install \
    && docker-php-ext-enable ast

RUN curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/5.3.2.tar.gz \
    && tar xfz /tmp/redis.tar.gz \
    && rm /tmp/redis.tar.gz \
    && mv phpredis-5.3.2 /usr/src/php/ext/redis \
    && docker-php-ext-install redis

RUN curl -sS https://getcomposer.org/installer | php; mv composer.phar /usr/local/bin/composer

COPY php-fpm.d/www.conf /usr/local/etc/php-fpm.d/
COPY custom-php.ini /usr/local/etc/php/conf.d/
COPY php-fpm.conf /usr/local/etc/php-fpm.conf

ARG USER
RUN useradd -ms /bin/bash ${USER} || true
ARG UID
ARG APP_DIR
RUN usermod -u ${UID} -d ${APP_DIR} ${USER} || true
ARG GID
RUN groupmod -g 1500 ${USER}
RUN groupmod -g ${GID} www-data || true
RUN usermod -a -G www-data ${USER}
RUN chown www-data:www-data ${APP_DIR} && chmod 750 ${APP_DIR}
RUN mkdir ${APP_DIR}/.symfony && chown ${USER}:www-data ${APP_DIR}/.symfony && chmod 750 ${APP_DIR}/.symfony
RUN mkdir ${APP_DIR}/.composer && chown ${USER}:www-data ${APP_DIR}/.composer && chmod 750 ${APP_DIR}/.composer
RUN mkdir ${APP_DIR}/.cache && chown ${USER}:www-data ${APP_DIR}/.cache && chmod 750 ${APP_DIR}/.cache

USER root
RUN wget https://get.symfony.com/cli/installer -O - | bash; mv /root/.symfony/bin/symfony /usr/local/bin/symfony
RUN curl -sSOL https://github.com/sensiolabs-de/deptrac/releases/download/0.10.0/deptrac.phar; \
    chmod +x deptrac.phar; mv deptrac.phar /usr/local/bin/deptrac
RUN curl -sSOL https://github.com/vimeo/psalm/releases/download/4.2.1/psalm.phar; \
    chmod +x psalm.phar; mv psalm.phar /usr/local/bin/psalm
RUN curl -sSOL https://github.com/phpstan/phpstan/releases/download/0.12.57/phpstan.phar; \
    chmod +x phpstan.phar; mv phpstan.phar /usr/local/bin/phpstan
RUN curl -sSOL https://github.com/phan/phan/releases/download/3.2.4/phan.phar; \
    chmod +x phan.phar; mv phan.phar /usr/local/bin/phan
RUN curl -sSOL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar; \
    chmod +x phpcs.phar; mv phpcs.phar /usr/local/bin/phpcs
RUN curl -sSOL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar; \
    chmod +x phpcbf.phar; mv phpcbf.phar /usr/local/bin/phpcbf

WORKDIR ${APP_DIR}
USER www-data
CMD ["php-fpm"]
