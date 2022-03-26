# hadolint ignore=DL3006,DL3007
ARG VERSION

FROM eafxx/alpine-python

ENV \
  APP_DIR=traktarr \
  TRAKTARR_CONFIG=/config/config.json \
  TRAKTARR_LOGFILE=/config/traktarr.log \
  TZ=""

COPY ./apps/docker-traktarr/root/ /

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN \
  chmod +x /etc/s6/init/init-stage2 && \
  chmod +x /docker-mods && \
  apk add --no-cache curl git py3-setuptools tzdata bash && \
  if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python; fi && \
  pip3 install --no-cache-dir --upgrade pip setuptools && \
  if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip; fi

WORKDIR /${APP_DIR}

VOLUME /config
