# https://github.com/nsano-rururu/docker-compose-ui
# DOCKER-VERSION 19.03
FROM python:alpine3.15
MAINTAINER Naoyuki Sano <nsano@ae.em-net.ne.jp>

RUN apk add -U --no-cache cargo \
    git \
    gcc \
    libffi-dev \
    make \
    musl-dev \
    openssl \
    openssl-dev \
    nano \
    bash

COPY ./base/docker-ui/root/ .

RUN pip install virtualenv
RUN virtualenv /env && \
    /env/bin/python -m pip install --upgrade pip && \
    /env/bin/pip install --no-cache-dir cryptography && \
    /env/bin/pip install --no-cache-dir -r /app/requirements.txt && \
    set -ex && \
    apk update && apk upgrade && \
    echo "**** install build packages ****" && \
      apk add --no-cache --purge -uU \
         curl \
         tar \
         s6 \
         jq \
         musl \
         xz \
         procps \
         bash \
         wget \
         busybox \
         unzip \
         coreutils \
         shadow \
         findutils \
         apk-tools \
         procps \
         linux-headers && \
    S6_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | jq -r .tag_name) && \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-noarch.tar.xz | tar xvpfJ - -C / && \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-$(uname -m).tar.xz | tar xvpfJ - -C / && \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-symlinks-noarch.tar.xz | tar xvpfJ - -C / && \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-symlinks-arch.tar.xz | tar xvpfJ - -C / && \
    mkdir -p \
       /etc/cont-init.d \
       /etc/cont-finish.d \
       /etc/services.d \
       /app \
       /config \
       /defaults \
       /system && \
    chmod -R 755 \
       /app \
       /system \
       /etc/cont-init.d \
       /etc/cont-finish.d \
       /etc/services.d && \
    sed -i "s|s6-rc -v2|s6-rc -v1|g" /package/admin/s6-overlay/etc/s6-linux-init/skel/rc.init && \
    sed -i "s|s6-rc -v2|s6-rc -v1|g" /package/admin/s6-overlay/etc/s6-linux-init/skel/rc.shutdown && \
    sed -i "s|echo|# echo |g" /package/admin/s6-overlay/etc/s6-rc/scripts/cont-init && \
    sed -i "s|echo|# echo |g" /package/admin/s6-overlay/etc/s6-rc/scripts/cont-finish && \
    sed -i "s|echo ' (no readiness notification)'|# echo ' (no readiness notification)'|g" /package/admin/s6-overlay/etc/s6-rc/scripts/services-up && \
    sed -i "s|s6-echo -n|# s6-echo -n|g" /package/admin/s6-overlay/etc/s6-rc/scripts/services-up && \
    rm -rf /var/cache/apk/*

EXPOSE 5000
WORKDIR /opt/
ENTRYPOINT ["/init"]

