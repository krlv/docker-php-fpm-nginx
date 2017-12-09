FROM php:7.1-fpm-alpine

# install S6 overlay
ENV S6_OVERLAY_VERSION=v1.20.0.0
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

# configure php-fpm
RUN sed -i 's$access.log$;access.log$g' /usr/local/etc/php-fpm.d/docker.conf \
    && echo "listen = /var/run/php-fpm.sock" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
    && echo "listen.owner = nginx" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
    && echo "listen.group = nginx" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
    && echo "listen.mode = 0660" >> /usr/local/etc/php-fpm.d/zz-docker.conf \

EXPOSE 80

ENTRYPOINT ["/init"]