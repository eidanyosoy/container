FROM ubuntu:20.04

# set environment variables
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/root" \
    LANGUAGE="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    TERM="xterm"

RUN apt update -yqq && \
    apt upgrade -yqq && \
    apt install bash -yqq

COPY ./apps/docker-crunchy/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
##EOF
