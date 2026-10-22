
# Imagen base de Ubuntu
FROM ubuntu:latest

# Zona horaria
ENV TZ=Europe/Madrid
ENV DEBIAN_FRONTEND=noninteractive

# Instalamos Apache, PHP y las extensiones necesarias para Laravel
RUN apt-get update && \
    apt-get install -y \
        apache2 \
        php \
        libapache2-mod-php \
        php-cli \
        php-common \
        php-sqlite3 \
        php-mysql \
        php-pgsql \
        php-gd \
        php-zip \
        php-bcmath \
        php-mbstring \
        php-xml \
        php-curl \
        php-intl \
        unzip \
        zip \
        git \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Habilitamos las rutas de Laravel en Apache
RUN a2enmod rewrite

# Copiamos la configuración personalizada de Apache
COPY ./config/apache2.conf /etc/apache2/apache2.conf

# Directorio de trabajo del proyecto
WORKDIR /var/www/html/

# Copiamos el proyecto Laravel
COPY ./app /var/www/html/

# Instalamos Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Instalamos las dependencias de Laravel
RUN composer install \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

# Configuramos los permisos de Laravel
RUN chown -R www-data:www-data \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        /var/www/html/database && \
    chmod -R 775 \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        /var/www/html/database

# Configuramos el directorio público de Apache
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri \
    -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf

RUN sed -ri \
    -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

# Puerto HTTP
EXPOSE 80

# Arrancamos Apache en primer plano
CMD ["apachectl", "-D", "FOREGROUND"]
