FROM ghcr.io/linuxserver/baseimage-alpine:3.14
ARG VERSION
RUN \
 echo "**** install packages ****" && \
 apk update && apk add --no-cache \
	ca-certificates \
	curl \
	findutils \
	jq \
	openssl \
	p7zip \
	python3 \
	rsync \
	tar \
	transmission-cli \
	transmission-daemon \
	unrar \
	unzip && \
 echo "**** install transmission ****" && \
  apk add --no-cache \
	transmission-cli==${VERSION} \
	transmission-daemon==${VERSION} && \
 echo "**** install third party themes ****" && \
 curl -o \
	/tmp/combustion.zip -L \
	"https://github.com/Secretmapper/combustion/archive/release.zip" && \
 unzip \
	/tmp/combustion.zip -d \
	/ && \
 mkdir -p /tmp/twctemp && \
 TWCVERSION=$(curl -sX GET "https://api.github.com/repos/ronggang/transmission-web-control/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl -o \
	/tmp/twc.tar.gz -L \
	"https://github.com/ronggang/transmission-web-control/archive/${TWCVERSION}.tar.gz" && \
 tar xf \
	/tmp/twc.tar.gz -C \
	/tmp/twctemp --strip-components=1 && \
 mv /tmp/twctemp/src /transmission-web-control && \
 mkdir -p /kettu && \
 curl -o \
	/tmp/kettu.tar.gz -L \
	"https://github.com/endor/kettu/archive/master.tar.gz" && \
 tar xf \
	/tmp/kettu.tar.gz -C \
	/kettu --strip-components=1 && \
 curl -o \
	/tmp/flood-for-transmission.tar.gz -L \
	"https://github.com/johman10/flood-for-transmission/releases/download/latest/flood-for-transmission.tar.gz" && \
 tar xf \
	/tmp/flood-for-transmission.tar.gz -C \
	/ && \
 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/*

# copy local files
COPY ./apps/docker-transmission/root/ /

# ports and volumes
EXPOSE 9091 51413/tcp 51413/udp
VOLUME /config
