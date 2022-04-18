
# https://github.com/nsano-rururu/docker-compose-ui
# DOCKER-VERSION 19.03
FROM python:alpine3.15 AS builder
MAINTAINER Naoyuki Sano <nsano@ae.em-net.ne.jp>

RUN pip install virtualenv

RUN apk add -U --no-cache cargo \
    git \
    gcc \
    libffi-dev \
    make \
    musl-dev \
    openssl \
    openssl-dev

COPY ./base/docker-ui/root/app/requirements.txt /app/requirements.txt
RUN virtualenv /env && \
    /env/bin/python -m pip install --upgrade pip && \
    /env/bin/pip install --no-cache-dir cryptography && \
    /env/bin/pip install --no-cache-dir -r /app/requirements.txt

FROM python:alpine3.15

RUN apk add -U --no-cache git bash
COPY --from=builder /env /env
COPY ./base/docker-ui/root/app/ /app
ADD ./base/docker-ui/root/entrypoint.sh /app/entrypoint.sh

EXPOSE 5000

CMD []
ENTRYPOINT [ "bash", "/app/entrypoint.sh" ]
WORKDIR /opt
