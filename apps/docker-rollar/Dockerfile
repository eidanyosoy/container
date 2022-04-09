FROM ubuntu:21.10
LABEL org.opencontainers.image.source="https://github.com/dockserver/container"

ARG TARGETPLATFORM
ARG BUILDPLATFORM

ENV LANG=C.UTF-8 \
    GPG_KEY=A035C8C19219BA821ECEA86B64E628F8D684696D \
    PYTHON_VERSION=3.10.1 \
    PYTHON_PIP_VERSION=21.2.4 \
    PYTHON_SETUPTOOLS_VERSION=57.5.0 \
    PYTHON_GET_PIP_URL=https://github.com/pypa/get-pip/raw/3cb8888cc2869620f57d5d2da64da38f516078c7/public/get-pip.py \
    PYTHON_GET_PIP_SHA256=c518250e91a70d7b20cceb15272209a4ded2a0c263ae5776f129e0d9b5674309 \
    PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD ["bash"]

RUN \
    set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       netbase \
       tar \
       wget \
       dirmngr \
       gnupg \
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
       cron \
       vim \
       $(if apt-cache show 'default-libmysqlclient-dev' 2>/dev/null | grep -q '^Version:';then echo 'default-libmysqlclient-dev';else; echo 'libmysqlclient-dev';fi ) && \
   rm -rf /var/lib/apt/lists/*

RUN \
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
      rm python.tar.xz && \
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
    find /usr/local -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \ -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) \) \) -exec rm -rf '{}' + && \ \
    ldconfig && \
    python3 --version

RUN \
    set -ex && \
    cd /usr/local/bin && \
       ln -s idle3 idle && \
       ln -s pydoc3 pydoc && \
       ln -s python3 python && \
       ln -s python3-config python-config

RUN \
    set -ex && \
       wget -O get-pip.py "$PYTHON_GET_PIP_URL" && \
       echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict - && \
       python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PYTHON_PIP_VERSION" "setuptools==$PYTHON_SETUPTOOLS_VERSION" && \
       pip --version && \
       find /usr/local -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \) -exec rm -rf '{}' + && \
       rm -f get-pip.py

CMD [ "python3" ]

COPY ./root .

RUN \
 chmod 0644 /crontab \
 chmod 0744 /rollarr/*

RUN pip install -r /rollarr/requirements.txt
RUN /usr/bin/crontab /crontab

EXPOSE 3100

CMD ["./run.sh"]
