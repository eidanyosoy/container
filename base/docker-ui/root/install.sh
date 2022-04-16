#!/bin/bash
# ensure local python is preferred over distribution python

# runtime dependencies
set -eux; \
  apk add --no-cache \
  ca-certificates \
  tzdata \
;

GPG_KEY=A035C8C19219BA821ECEA86B64E628F8D684696D
PYTHON_VERSION=3.10.4
PYTHON_SETUPTOOLS_VERSION=62.0.0
LANG=C.UTF-8
TZ="UTC"
PUID="1000"
PGID="1000"
PYTHON_PIP_VERSION=22.0.4
PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

set -eux; \
\
apk add --no-cache --virtual .build-deps \
gnupg \
tar \
xz \
\
bluez-dev \
bzip2-dev \
dpkg-dev dpkg \
expat-dev \
findutils \
gcc \
gdbm-dev \
libc-dev \
libffi-dev \
libnsl-dev \
libtirpc-dev \
linux-headers \
make \
ncurses-dev \
openssl-dev \
pax-utils \
readline-dev \
sqlite-dev \
tcl-dev \
tk \
tk-dev \
util-linux-dev \
xz-dev \
zlib-dev \

set -eux; \
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
     EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000" \
     LDFLAGS="-Wl,--strip-all" \
     ; \
     make install; \
     cd /; \
     rm -rf /usr/src/python; \
     find /usr/local -depth \ \( \ \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \ -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \ \) -exec rm -rf '{}' + \
     ; \
     find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' | xargs -rt apk add --no-network --virtual .python-rundeps \
     ; \
     apk del --no-network .build-deps; \
     python3 --version

set -eux; \
for src in idle3 pydoc3 python3 python3-config; do \
	dst="$(echo "$src" | tr -d 3)"; \
	[ -s "/usr/local/bin/$src" ]; \
	[ ! -e "/usr/local/bin/$dst" ]; \
	ln -svT "$src" "/usr/local/bin/$dst"; \
done

set -eux; \
     curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
      python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PYTHON_PIP_VERSION" "setuptools==$PYTHON_SETUPTOOLS_VERSION" && \
   find /usr/local -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \) -exec rm -rf '{}' + && \
      rm -rf get-pip.py && \
      pip install --no-warn-script-location --upgrade --no-cache-dir --force-reinstall -r /rollarr/requirements.txt

