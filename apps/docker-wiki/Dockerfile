#####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
#####################################
# THIS DOCKER IS UNDER LICENSE      #
# NO CUSTOMIZING IS ALLOWED         #
# NO REBRANDING IS ALLOWED          #
# NO CODE MIRRORING IS ALLOWED      #
#####################################
FROM alpine:3.17.2 as buildstage
LABEL maintainer=dockserver

RUN \
   echo "**** install packages ****" && \
      apk add --update --no-cache git && \
   echo "**** clone repositories ****" && \
      mkdir -p /app && git clone --quiet https://github.com/dockserver/dockserver.git /app

FROM ghcr.io/squidfunk/mkdocs-material:latest

COPY --from=buildstage /app/wiki /docs

RUN \
   echo "**** install packages ****" && \
      python3 -m pip install --upgrade pip && \
      python3 -m pip install --no-warn-script-location --upgrade --force-reinstall -r /docs/requirements.txt && \
      rm -rf /tmp/* && rm -rf /var/cache/apk/* && rm -rf /root/.cache

WORKDIR /docs

EXPOSE 8000
ENTRYPOINT ["mkdocs"]
CMD [ "serve" , "--dev-addr=0.0.0.0:8000" ]
