FROM alpine:latest
ARG PLATFORM
ARG VERSION

STOPSIGNAL SIGTERM

ENV JD_EMAIL="" \
    JD_PASSWORD="" \
    JD_DEVICENAME="" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

RUN apk -U upgrade \
    && apk add --no-cache \
        bash \
        curl \
        wget \
        openjdk8-jre \
        ffmpeg \
        unzip

WORKDIR /jdownloader

COPY ./apps/docker-jdownloader/root/ .

RUN chmod 777 \
    . \
    docker-entrypoint.sh \
    functions.sh \
    setup.sh \
    org.jdownloader.extensions.eventscripter.EventScripterExtension.json \
    org.jdownloader.extensions.eventscripter.EventScripterExtension.scripts.json

CMD ["/bin/bash", "-c", "./docker-entrypoint.sh"]
