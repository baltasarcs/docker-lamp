FROM php:8-apache-buster
MAINTAINER Baltasar Santos <baltasarc.s@gmail.com>

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
    " \
    && apt-get update -yqq && apt full-upgrade -yqq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y $buildDeps $runtimeDeps && rm -rf /var/lib/apt/lists/*\
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-install bcmath bz2 iconv intl json opcache zip soap dom xsl xml fileinfo gd mbstring pdo pdo_mysql mysqli \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) gd \
#   && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && docker-php-ext-install ldap \
    && pecl install memcached redis mongodb xdebug \
#   && docker-php-ext-enable memcached.so redis.so mysqli.so mongodb.so pdo_mysql.so pdo.so soap.so gd.so zip.so xdebug \
    && docker-php-ext-enable xdebug \
    && CFLAGS="-I/usr/src/php" docker-php-ext-install xmlreader \
    && apt-get purge -y --auto-remove $buildDeps \
#   && rm -r /var/lib/apt/lists/* \
    && echo 'ServerName localhost' >> /etc/apache2/apache2.conf \
    && a2enmod rewrite && a2enmod proxy && a2enmod proxy_http \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    # install nodejs and npm
    RUN curl -sL https://deb.nodesource.com/setup_11.x | bash - && apt-get install -y nodejs

    # Install and config XDebug
    RUN echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_handler=dbgp" >>  /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_autostart=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_connect_back=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.idekey=docker" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_log=/var/log/xdebug.log" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.default_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini

    # enable colors on terminal
    RUN { \
	echo 'alias ls="ls --color=auto"'; \
    echo 'alias grep="grep --color=auto"'; \
    } > /root/.bashrc

    RUN mv /root/bkp-preferences /etc/apt/preferences.d/no-debian-php
    RUN echo "America/Sao_Paulo" > /etc/timezone
    RUN dpkg-reconfigure -f noninteractive tzdata

# COPY ./../php/7.4/php.ini /usr/local/etc/php
# COPY ./data/config/apache2 /etc/apache2/sites-available

EXPOSE 80 443 9000

WORKDIR /var/www/html

CMD apachectl -D FOREGROUND
