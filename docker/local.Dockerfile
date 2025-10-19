FROM php:8.3-fpm-alpine

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
    && docker-php-ext-enable redis

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Crear usuario con el mismo UID/GID que el host
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
    # Crear grupo si no existe
    if ! getent group ${GROUP_ID} >/dev/null; then \
        addgroup -g ${GROUP_ID} laravel; \
    fi && \
    # Crear usuario si no existe
    if ! getent passwd ${USER_ID} >/dev/null; then \
        adduser -D -u ${USER_ID} -G $(getent group ${GROUP_ID} | cut -d: -f1) laravel; \
    fi \
;fi

# Configurar directorio de trabajo
WORKDIR /var/www/html

# Cambiar permisos del directorio
RUN chown -R ${USER_ID}:${GROUP_ID} /var/www/html

# Usar el usuario creado
USER ${USER_ID}

# Exponer puerto
EXPOSE 9000

CMD ["php-fpm"]