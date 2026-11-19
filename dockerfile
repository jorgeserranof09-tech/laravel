# Utilizamos la última imagen de ubuntu como imagen base
FROM ubuntu:24.04

# Establecemos el timezone
ENV TZ=Europe/Madrid

# 1. Instalamos el comando add-apt-repository y añadimos el PPA de Ondřej Surý
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common gnupg2 ca-certificates && \
    add-apt-repository -y ppa:ondrej/php && \
    apt-get update

# Instalamos Apache y PHP
RUN apt-get install -y --no-install-recommends \
        apache2 \
        php8.5=8.5.12* \
        libapache2-mod-php8.5=8.5.12* \
        php8.5-cli=8.5.12* \
        php8.5-common=8.5.12* \
        php8.5-mysql=8.5.12* \
        php8.5-pgsql=8.5.12* \
        php8.5-sqlite3=8.5.12* \
        php8.5-gd=8.5.12* \
        php8.5-zip=8.5.12* \
        php8.5-bcmath=8.5.12* \
        php8.5-mbstring=8.5.12* \
        php8.5-xml=8.5.12* \
        php8.5-curl=8.5.12* \
        php8.5-intl=8.5.12* \
        unzip \
        zip \
        git \
        curl \
        && rm -rf /var/lib/apt/lists/*

# Copiamos la configuración personalizada de Apache
COPY ./config/apache2.conf /etc/apache2/apache2.conf

# Desactivamos el módulo autoindex
RUN a2dismod -f autoindex

# Habilitamos mod_rewrite para las rutas de Laravel
RUN a2enmod rewrite

# Creamos directorios necesarios
RUN mkdir -p /var/run/apache2 /var/lock/apache2 /var/log/apache2

# Damos permisos al usuario de Apache
RUN chown -R www-data:www-data \
    /var/run/apache2 /var/lock/apache2 /var/log/apache2

# Copiamos nuestra aplicación al directorio web
COPY ./app /var/www/html/

# Establecemos el directorio de trabajo
WORKDIR /var/www/html/

# Instalamos Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Instalamos las dependencias de Composer
RUN composer install \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

# Permisos de Laravel
RUN chmod -R 775 /var/www/html/storage && \
    chmod -R 775 /var/www/html/bootstrap/cache

# Cambiamos al usuario www-data
USER www-data

# Ponemos el puerto 80 del contenedor en escucha
EXPOSE 80

# Levantamos Apache
CMD ["apachectl", "-D", "FOREGROUND"]

# para que funcione el run mkdir
USER root

# Construimos el directorio /data
RUN mkdir /data && chown -R www-data /data && chmod 755 /data && chmod 775 -R /var/www/html/

# para que vuelve www-data
USER www-data

# Configuracion para Apache despues de configuracion HTTPS
USER root

# Habilitamos el módulo ssl en apache
RUN a2enmod ssl headers


# Copiamos el fichero de configuración del virtual host
COPY ./config/divflex.freeddns.org.conf /etc/apache2/sites-available/divflex-ssl.conf

# Activamos nuestro sitio y desactivamos el sitio por defecto
RUN a2dissite 000-default && a2ensite divflex-ssl

# Ponemos el puerto 443 en escucha
EXPOSE 443