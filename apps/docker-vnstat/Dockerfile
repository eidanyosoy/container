ARG VERSION

FROM php:${VERSION}
# hadolint ignore=DL3008,DL3009,DL3015,DL3059,DL4006

RUN \
  echo "**** install build packages ****" && \
     rm -rf /etc/apt/sources.list && \
  echo "deb http://ftp.debian.org/debian experimental main" >>/etc/apt/sources.list && \
  echo "deb http://ftp.debian.org/debian sid main" >>/etc/apt/sources.list && \
     apt-get update -yqq && \
     apt-get install -yqq git unzip apt-utils && \
     apt-get purge libgcc-8-dev -yqq && \
     apt-get autoremove -yqq && apt-get autoclean -yqq && \
     apt-get -t experimental install libc6-dev -yqq && \
     apt-get autoremove -yqq && apt-get autoclean -yqq

# hadolint ignore=DL3008,DL3009,DL3015,DL3059,DL4006

RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

COPY ./apps/docker-vnstat/app/ /var/www/html/
# hadolint ignore=DL3008,DL3009,DL3015,DL3059,DL4006

RUN composer install --quiet && mkdir -p /var/lib/vnstat
