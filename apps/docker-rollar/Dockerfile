FROM ubuntu:21.10
LABEL org.opencontainers.image.source="https://github.com/dockserver/container"

ARG TARGETPLATFORM
ARG BUILDPLATFORM

ENV LANG=C.UTF-8 \
    TZ="UTC" \
    PUID="1000" \
    PGID="1000" \
    DEBIAN_FRONTEND="noninteractive" \
    GPG_KEY=A035C8C19219BA821ECEA86B64E628F8D684696D \
    PYTHON_VERSION=3.10.1 \
    PYTHON_PIP_VERSION=21.2.4 \
    PYTHON_SETUPTOOLS_VERSION=57.5.0 \
    PYTHON_GET_PIP_URL=https://github.com/pypa/get-pip/raw/3cb8888cc2869620f57d5d2da64da38f516078c7/public/get-pip.py \
    PYTHON_GET_PIP_SHA256=c518250e91a70d7b20cceb15272209a4ded2a0c263ae5776f129e0d9b5674309 \
    PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD ["bash"]

ADD ./root/install.sh .

RUN \
    chmod 755 install.sh && \
    bash -xv install.sh

CMD [ "python3" ]

COPY ./root .

RUN \
   chmod 0644 /crontab \
   chmod 0744 /rollarr/* \
   pip install -r /rollarr/requirements.txt

RUN /usr/bin/crontab /crontab

EXPOSE 3100

CMD ["./run.sh"]
