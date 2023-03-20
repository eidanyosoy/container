FROM alpine:3.17
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG VERSION

RUN \
 echo "**** update build packages ****" && \
   apk --quiet --no-cache --no-progress update && \
   apk --quiet --no-cache --no-progress upgrade && \
 echo "**** install build packages ****" && \
   apk add --no-cache bash curl tzdata xz coreutils shadow curl tar jq

RUN set -x && OVERLAY_ARCH=$(uname -m) \
  && case "${OVERLAY_ARCH}" in \
    x86_64) OVERLAY_ARCH='amd64';; \
    arm) OVERLAY_ARCH='armhf';; \
    aarch64) OVERLAY_ARCH='aarch64';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && OVERLAY_VERSION=$(curl -sL "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | jq -r '. | .tag_name') \
  && curl -L -s https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz | tar xvzf - -C / \
  && apk del --no-cache curl && apk del --purge &&  rm -rf /tmp/*

COPY ./base/docker-alpine/patch/ /tmp/patch

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
HOME="/root" \
TERM="xterm"

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies curl patch tar && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache ca-certificates coreutils procps shadow tzdata bash curl bc findutils coreutils && \
 echo "**** create abc user and make our folders ****" && \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc && \
 mkdir -p \
	/app \
	/config \
	/defaults \
	/system && \
 mv /usr/bin/with-contenv /usr/bin/with-contenvb && \
 patch -u /etc/s6/init/init-stage2 -i /tmp/patch/etc/s6/init/init-stage2.patch

RUN \
  QARCH=$(uname -m) \
  && case "${QARCH}" in \
  aarch64) \
     curl -o /usr/bin/qemu-${QARCH}-static -L "https://lsio-ci.ams3.digitaloceanspaces.com/qemu-${ARCH}-static" && \
     chmod +x /usr/bin/qemu-${QARCH}-static; \
  ;; \
  arm) \
     curl -o /usr/bin/qemu-${QARCH}-static -L "https://lsio-ci.ams3.digitaloceanspaces.com/qemu-${ARCH}-static" && \
     chmod +x /usr/bin/qemu-${QARCH}-static; \
  ;; \
  esac \
  && \
  apk del --purge build-dependencies && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/*

COPY ./base/docker-alpine/root/ /

ENTRYPOINT ["/init"]
