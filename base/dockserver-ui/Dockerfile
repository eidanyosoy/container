FROM python:alpine3.15 AS builder

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

COPY ./base/dockserver-ui/root/ .

# install python dependencies
RUN pip install virtualenv && \
    apk add -U --no-cache --virtual=build-dependencies cargo \
       git \
       gcc \
       libffi-dev \
       make \
       musl-dev \
       openssl \
       openssl-dev

RUN virtualenv /env && \
    /env/bin/python -m pip install --no-warn-script-location --upgrade pip setuptools && \
    /env/bin/pip install --no-warn-script-location --no-cache-dir cryptography && \
    /env/bin/pip install --no-warn-script-location --no-cache-dir -r requirements.txt && \
    rm -rf requirements.txt && \
    apk del --purge build-dependencies && \
    rm -rf /var/cache/apk/* /tmp/* 


#FINAL IMAGE

FROM python:alpine3.15

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN apk add -U --no-cache git bash rsync && \
    rm -rf /var/cache/apk/* /tmp/*

COPY --from=builder /env /env
COPY ./base/dockserver-ui/root/ .

# gunicorn
CMD ["gunicorn", "--config", "gunicorn-cfg.py", "run:app"]
