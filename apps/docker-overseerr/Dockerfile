FROM ghcr.io/linuxserver/baseimage-alpine:3.17

# set version label
ARG VERSION
# set environment variables
ENV HOME="/config"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    curl \
    g++ \
    make \
    python3 && \
  echo "**** symlink python3 for compatibility ****" && \
  ln -s /usr/bin/python3 /usr/bin/python && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    yarn && \
  export COMMIT_TAG="v${VERSION}" && \
  curl -o \
    /tmp/overseerr.tar.gz -L \
    "https://github.com/sct/overseerr/archive/refs/tags/v${VERSION}.tar.gz" && \
  mkdir -p /app/overseerr && \
  tar xzf \
    /tmp/overseerr.tar.gz -C \
    /app/overseerr/ --strip-components=1 && \
  cd /app/overseerr && \
  export NODE_OPTIONS=--max_old_space_size=2048 && \
  yarn --frozen-lockfile --network-timeout 1000000 && \
  yarn build && \
  yarn install --production --ignore-scripts --prefer-offline && \
  yarn cache clean && \
  rm -rf \
    /app/overseerr/src \
    /app/overseerr/server \
    /app/overseerr/Dockerfile && \
  echo "{\"commitTag\": \"${COMMIT_TAG}\"}" > committag.json && \
  rm -rf /app/overseerr/config && \
  ln -s /config /app/overseerr/config && \
  touch /config/DOCKER && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /tmp/*

# copy local files
COPY ./apps/docker-overseerr/root/ /

# ports and volumes
EXPOSE 5055

VOLUME /config
