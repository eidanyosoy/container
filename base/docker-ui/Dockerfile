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

COPY ./base/docker-ui/root/ /

RUN pip install virtualenv
RUN virtualenv /env && \
    /env/bin/python -m pip install --upgrade pip && \
    /env/bin/pip install --no-cache-dir cryptography && \
    /env/bin/pip install --no-cache-dir -r /app/requirements.txt

EXPOSE 5000

CMD []
ENTRYPOINT ["/env/bin/python", "/app/main.py"]

WORKDIR ["/opt"]
