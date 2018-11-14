FROM php:7.2-fpm-alpine

# install S6 overlay
ENV S6_OVERLAY_VERSION=v1.21.7.0
RUN apk add --no-cache curl \
    && curl -L -s https://github.com/just-containers/s6-overlay/releases/download/$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz | tar xvzf - -C / \
    && apk del --no-cache curl

# install nginx
RUN apk add --update --no-cache nginx \
    # forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# install and enable php extensions
RUN docker-php-source extract \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install \
       apcu \
       xdebug \
    && docker-php-ext-install \
       pdo \
       pdo_mysql \
    && docker-php-ext-enable \
       apcu \
       opcache \
       pdo \
       pdo_mysql \
       xdebug \
    && docker-php-source delete \
    && apk del .build-deps

# copy config files
COPY docker/s6/ /etc/
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/nginx.vh.default.conf /etc/nginx/conf.d/default.conf
COPY docker/php-fpm/docker.conf /usr/local/etc/php-fpm.d/docker.conf
COPY docker/php-fpm/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf

EXPOSE 80

ENTRYPOINT ["/init"]