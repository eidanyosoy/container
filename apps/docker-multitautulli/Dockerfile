FROM ghcr.io/linuxserver/baseimage-alpine:3.17

ARG VERSION

# Inform app this is a docker env
ENV TAUTULLI_DOCKER=True

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies \
	g++ \
	gcc \
	make \
	py3-pip \
	python3-dev && \
 echo "**** install packages ****" && \
 apk add --no-cache \
 	curl \
	jq \
	py3-openssl \
	py3-setuptools \
	python3 && \
 echo "**** install pip packages ****" && \
 pip3 install --no-cache-dir -U \
	mock \
	tzlocal \
	plexapi \
	cherrypy \
	pycryptodomex && \
 echo "**** install app ****" && \
   mkdir -p /app/tautulli && \
   RELEASE=$(curl -sX GET "https://api.github.com/repos/zSeriesGuy/Tautulli/releases/latest" | jq -r '. | .tag_name')  && \
      curl -o /tmp/tautulli.tar.gz -L "https://github.com/zSeriesGuy/Tautulli/archive/${RELEASE}.tar.gz" && \
      tar xf /tmp/tautulli.tar.gz -C /app/tautulli --strip-components=1 && \
 echo "**** Hard Coding versioning ****" && \
    echo "${RELEASE}" > /app/tautulli/version.txt && \
    echo "master" > /app/tautulli/branch.txt && \
 echo "**** cleanup ****" && \
    apk del --purge build-dependencies && \
 rm -rf \
    /root/.cache \
    /tmp/*

# add local files
COPY ./apps/docker-multitautulli/root/ /

# ports and volumes
VOLUME /config

EXPOSE 8181
