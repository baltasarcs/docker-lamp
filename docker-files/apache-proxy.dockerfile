FROM debian:buster-slim

MAINTAINER Baltasar Santos "baltasarc.s@gmail.com"

ENV DEBIAN_FRONTEND noninteractive

#Install apache 
RUN apt -y update && apt -y install apache2 vim

#Enable proxy mode
RUN a2enmod proxy \
    && a2enmod proxy_http \
    && a2enmod ssl \
    && a2enmod rewrite \
    && a2enmod proxy_fcgi \
    && service apache2 stop

#Ports
EXPOSE 80 443

#Volumes
#VOLUME /opt/proxy-conf
VOLUME /etc/apache2/sites-available

#Launch Apache2 on FOREGROUND
COPY script/apache-proxy-start.sh /opt/
RUN chmod +x /opt/apache-proxy-start.sh
ENTRYPOINT ["/opt/apache-proxy-start.sh"]
