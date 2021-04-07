FROM php:5.6-apache-stretch

RUN apt -y update

RUN apt -y install libxml2-dev

RUN docker-php-ext-install pdo_mysql

RUN docker-php-ext-install xml
