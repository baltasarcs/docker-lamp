FROM php:7.4-apache-buster
LABEL maintainer="Baltasar Santos <baltasarc.s@gmail.com>"

RUN mv /etc/apt/preferences.d/no-debian-php /root/bkp-preferences

# Install PHP extensions and PECL modules.
RUN buildDeps=" \
        libbz2-dev \
        libmemcached-dev \
        libsasl2-dev \
    " \
    runtimeDeps=" \
        curl \
        git \
        wget \
        vim \
        openssl \
        libzip-dev \
        unzip \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        libmemcachedutil2 \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libmcrypt-dev \
        libxslt-dev \
    	libonig-dev \
        zlib1g-dev \
	    php-soap \
        gnupg \
        libjpeg62-turbo-dev \
        cron \
    " \
    && apt-get update -yqq && apt full-upgrade -yqq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y $buildDeps $runtimeDeps && rm -rf /var/lib/apt/lists/*\
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-install bcmath bz2 iconv intl json opcache zip mbstring soap dom xsl xml fileinfo mbstring pdo pdo_mysql mysqli \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && pecl install memcached redis mongodb xdebug \
#   && docker-php-ext-enable memcached.so redis.so mysqli.so mongodb.so pdo_mysql.so pdo.so soap.so gd.so zip.so xdebug \
    && docker-php-ext-enable xdebug \
    && CFLAGS="-I/usr/src/php" docker-php-ext-install xmlreader \
    && apt-get purge -y --auto-remove $buildDeps \
    && echo 'ServerName localhost' >> /etc/apache2/apache2.conf \
    && a2enmod rewrite && a2enmod proxy && a2enmod proxy_http && a2enmod ssl

    # Install gd and requirements
    RUN apt-get install -y --no-install-recommends libpng-dev libjpeg62-turbo-dev libfreetype6-dev && \
    docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-install gd

    # install nodejs and npm
    RUN curl -sL https://deb.nodesource.com/setup_15.x | bash - && apt-get install -y --no-install-recommends nodejs

    # Set Timezone
    RUN mv /root/bkp-preferences /etc/apt/preferences.d/no-debian-php
    RUN echo "America/Sao_Paulo" > /etc/timezone
    RUN dpkg-reconfigure -f noninteractive tzdata

    # Install Composer
    RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Clear package lists and clear source
RUN rm -rf /var/lib/apt/lists/* && apt-get autoremove -y && docker-php-source delete

# COPY ./../php/7.4/php.ini /usr/local/etc/php
# COPY ./data/config/apache2 /etc/apache2/sites-available

# Permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod u+rwx,g+rx,o+rx /var/www/html && \
    find /var/www/html -type d -exec chmod u+rwx,g+rx,o+rx {} + && \
    find /var/www/html -type f -exec chmod u+rw,g+rw,o+r {} +

EXPOSE 80 443

WORKDIR /var/www/html

#Launch Apache2 on FOREGROUND
COPY script/apache-proxy-start.sh /opt/
RUN chmod +x /opt/apache-proxy-start.sh
ENTRYPOINT ["/opt/apache-proxy-start.sh"]

#CMD apachectl -D FOREGROUND
