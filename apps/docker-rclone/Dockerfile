#####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
FROM alpine:3.17
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN \
    echo "**** update build ****" && \
    apk --quiet --no-cache --no-progress update && \
    apk --quiet --no-cache --no-progress upgrade
RUN \
    echo "**** install build packages ****" && \
    apk --quiet --no-cache --no-progress add bash musl shadow && \
    apk del --quiet --clean-protected --no-progress && \
    rm -f /var/cache/apk/*

COPY ./apps/docker-rclone/root/ /

ENTRYPOINT [ "/bin/bash", "/start.sh" ]
