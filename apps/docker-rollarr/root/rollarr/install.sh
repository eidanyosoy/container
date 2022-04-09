#!/bin/bash

## GENERALL SETTINGS
LANG=C.UTF-8
TZ="UTC"
PUID="1000"
PGID="1000"
DEBIAN_FRONTEND="noninteractive"
GPG_KEY=A035C8C19219BA821ECEA86B64E628F8D684696D
PYTHON_VERSION=3.10.1
PYTHON_PIP_VERSION=22.0.4
PYTHON_SETUPTOOLS_VERSION=62.0.0
PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

set -eux && \
   apt-get update && \
   apt-get install -yqq --no-install-recommends ca-certificates curl netbase wget && \
   rm -rf /var/lib/apt/lists/*

set -eux && \
   if ! command -v gpg > /dev/null; then
      apt-get update -yqq && \
      apt-get install -yqq --no-install-recommends gnupg dirmngr && \
      rm -rf /var/lib/apt/lists/*
   fi

set -eux && \
   apt-get update -yqq && \
   apt-get install -yqq --no-install-recommends git mercurial openssh-client subversion procps && \
   rm -rf /var/lib/apt/lists/*

set -eux && \
   apt-get update -yqq && \
   apt-get install -yqq --no-install-recommends \
     autoconf \
     automake \
     bzip2 \
     dpkg-dev \
     file \
     g++ \
     gcc \
     imagemagick \
     libbz2-dev \
     libc6-dev \
     libcurl4-openssl-dev \
     libdb-dev \
     libevent-dev \
     libffi-dev \
     libgdbm-dev \
     libglib2.0-dev \
     libgmp-dev \
     libjpeg-dev \
     libkrb5-dev \
     liblzma-dev \
     libmagickcore-dev \
     libmagickwand-dev \
     libmaxminddb-dev \
     libncurses5-dev \
     libncursesw5-dev \
     libpng-dev \
     libpq-dev \
     libreadline-dev \
     libsqlite3-dev \
     libssl-dev \
     libtool \
     libwebp-dev \
     libxml2-dev \
     libxslt-dev \
     libyaml-dev \
     make \
     patch \
     unzip \
     xz-utils \
     zlib1g-dev \
     $( if apt-cache show 'default-libmysqlclient-dev' 2>/dev/null | grep -q '^Version:'; then echo 'default-libmysqlclient-dev'; else echo 'libmysqlclient-dev'; fi ) && \
     rm -rf /var/lib/apt/lists/*

set -ex && \
   apt-get update -yqq && \
   apt-get install -yqq --no-install-recommends libbluetooth-dev tk-dev uuid-dev && \
   rm -rf /var/lib/apt/lists/*

set -ex && \
   wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" && \
   wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" && \
   export GNUPGHOME="$(mktemp -d)" && \
     gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY" && \
     gpg --batch --verify python.tar.xz.asc python.tar.xz && \
     { command -v gpgconf > /dev/null && gpgconf --kill all || :; } && \
     rm -rf "$GNUPGHOME" python.tar.xz.asc && \
     mkdir -p /usr/src/python && \
     tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz && \
     rm -rf python.tar.xz && \
     cd /usr/src/python && \
       gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
       ./configure \
          --build="$gnuArch" \
          --enable-loadable-sqlite-extensions \
          --enable-optimizations \
          --enable-option-checking=fatal \
          --enable-shared \
          --with-lto \
          --with-system-expat \
          --with-system-ffi \
          --without-ensurepip && \
     make -j "$(nproc)" && \
     make install && \
     rm -rf /usr/src/python && \
     find /usr/local -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) \) \) -exec rm -rf '{}' + && \
     ldconfig && python3 --version

cd /usr/local/bin && \
   ln -s idle3 idle && \
   ln -s pydoc3 pydoc && \
   ln -s python3 python && \
   ln -s python3-config python-config

set -ex && \
   curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
      python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PYTHON_PIP_VERSION" "setuptools==$PYTHON_SETUPTOOLS_VERSION" && \
      pip --version && \
   find /usr/local -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \) -exec rm -rf '{}' + && \
      rm -rf get-pip.py && \
      python3 -m pip install --upgrade pip && \
      python3 -m pip install --no-warn-script-location --upgrade --python-version="${PYTHON_VERSION}" --force-reinstall -r /rollarr/requirements.txt && \
   rm -rf /tmp/* && \
   rm -rf /var/lib/apt/lists/* && \
   rm -rf /root/.cache

echo -e "#run python script every hour
0 * * * * /usr/local/bin/python /rollarr/PrerollUpdate.py > /proc/1/fd/1 2>/proc/1/fd/2
#empty" >/crontab.conf

/usr/bin/crontab /crontab.conf

mkdir -p /config && \
ln -s /rollarr/data.json /config/data.json

