# https://github.com/nsano-rururu/docker-compose-ui
# DOCKER-VERSION 19.03
FROM python:alpine3.15 as builder
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

COPY ./base/docker-ui/root/ .

RUN pip install virtualenv
RUN virtualenv /env && \
    /env/bin/python -m pip install --upgrade pip && \
    /env/bin/pip install --no-cache-dir cryptography && \
    /env/bin/pip install --no-cache-dir -r /app/requirements.txt

## FINAL IMAGE 
FROM ghcr/dockserver/docker-alpine-v3:latest 

CMD [ "bash" ]
RUN apk add bash && chmod -R 755 /app/* && bash /app/install.sh 
CMD []
COPY --from=builder /env /env
COPY --from=builder /app /app

EXPOSE 5000
ENTRYPOINT ["/init"]
WORKDIR ["/opt"]
