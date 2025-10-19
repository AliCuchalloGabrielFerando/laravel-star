# Usar versión estable y probada
FROM php:8.3.14-fpm-alpine3.20

# ⚡ ESTO SOLUCIONA LA MAYORÍA DE VULNERABILIDADES
# Actualizar TODOS los paquetes del sistema a sus últimas versiones
RUN apk update && \
    apk upgrade --no-cache && \
    rm -rf /var/cache/apk/*

# Instalar dependencias del sistema
RUN apk add --no-cache \
    git \
    curl \
    zip \
    unzip \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    oniguruma-dev \
    libxml2-dev \
    libzip-dev \
    mysql-client \
    postgresql-dev \
    openssh-client \
    bash \
    shadow

# Instalar extensiones de PHP necesarias para Laravel
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    opcache

# Instalar Redis extension
RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del $PHPIZE_DEPS \
    && rm -rf /tmp/pear

# Instalar Composer desde versión específica
COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

# Configuración de seguridad de PHP
RUN { \
    echo 'expose_php = Off'; \
    echo 'display_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /var/log/php_errors.log'; \
    echo 'upload_max_filesize = 10M'; \
    echo 'post_max_size = 10M'; \
    echo 'memory_limit = 256M'; \
    echo 'max_execution_time = 30'; \
    echo 'max_input_time = 60'; \
} > /usr/local/etc/php/conf.d/security.ini

# Crear usuario con el mismo UID/GID que el host
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
    if ! getent group ${GROUP_ID} >/dev/null; then \
        addgroup -g ${GROUP_ID} laravel; \
    fi && \
    if ! getent passwd ${USER_ID} >/dev/null; then \
        adduser -D -u ${USER_ID} -G $(getent group ${GROUP_ID} | cut -d: -f1) laravel; \
    fi \
;fi

WORKDIR /var/www/html

RUN chown -R ${USER_ID}:${GROUP_ID} /var/www/html

RUN mkdir -p /var/log && touch /var/log/php_errors.log && \
    chown ${USER_ID}:${GROUP_ID} /var/log/php_errors.log

USER ${USER_ID}

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD php-fpm -t || exit 1

EXPOSE 9000

CMD ["php-fpm"]