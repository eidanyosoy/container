#####################################
# Original coder Xaritomi -SBOX     #
#####################################
FROM alpine:3.17.2 as buildstage

RUN \
   echo "**** install packages ****" && \
   apk add --update --no-cache git && \
   mkdir -p /app && \
   git clone --quiet https://github.com/Xarritomi/auto-replyarr.git /app && \
   rm -rf /app/*.md \
          /app/Dockerfile \
          docker-compose.yml

FROM node:16-alpine3.14
COPY --from=buildstage /app /app

WORKDIR /app

RUN \
  apk add --update --no-cache ca-certificates bash && \
  mkdir -p /config

RUN \
   npm install -g npm@8.1.4 && \
   npm install -g ts-node && \ 
   npm install

ENV DOCKER=true

VOLUME [ "/config" ]

CMD ["/bin/bash", "/app/entrypoint.sh"]
