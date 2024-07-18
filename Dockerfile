# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/unrar:latest AS unrar

FROM ghcr.io/linuxserver/baseimage-alpine:3.20

# set version label
ARG BUILD_DATE
ARG VERSION
ARG DELUGE_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment variables
ENV PYTHON_EGG_CACHE="/config/plugins/.python-eggs" \
  TMPDIR=/run/deluged-temp

ENV FILEBOT_VERSION=4.7.19.5
ENV FILEBOT_URL=https://github.com/bigoulours/filebot/releases/download/$FILEBOT_VERSION/FileBot_$FILEBOT_VERSION-portable.tar.gz

# install software
RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --upgrade --virtual=build-dependencies \
    build-base && \
  echo "**** install packages ****" && \
  apk add --no-cache --upgrade --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    python3 \
    py3-future \
    py3-geoip \
    py3-requests \
    p7zip && \
  if [ -z ${DELUGE_VERSION+x} ]; then \
    DELUGE_VERSION=$(curl -sL "http://dl-cdn.alpinelinux.org/alpine/edge/community/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp \
    && awk '/^P:deluge$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://'); \
  fi && \
  apk add -U --upgrade --no-cache \
    deluge==${DELUGE_VERSION} && \
  echo "**** grab GeoIP database ****" && \
  curl -L --retry 10 --retry-max-time 60 --retry-all-errors \
    "https://mailfud.org/geoip-legacy/GeoIP.dat.gz" \
    | gunzip > /usr/share/GeoIP/GeoIP.dat && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  #Download Filebot
  mkdir /tmp/filebot && \
  curl -# -L -f ${FILEBOT_URL} | tar xz -C /tmp/filebot && \
  mkdir -p /opt/filebot/data && \
  mkdir -p /opt/filebot/lib/x86_64/ && \
  cp /tmp/filebot/lib/x86_64/libjnidispatch.so /opt/filebot/lib/x86_64/ && \
  cp /tmp/filebot/filebot.sh /opt/filebot/ && \
  cp /tmp/filebot/FileBot.jar /opt/filebot/ && \
  chmod 777 -R /opt/filebot/data && \
  ln -s /opt/filebot/filebot.sh /usr/bin/filebot && \
  # Dependencies
  apk add --no-cache --upgrade \
    openjdk21-jre \
    libmediainfo \
    && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    $HOME/.cache \
    /tmp/*

# add local files
COPY root/ /

# add unrar
COPY --from=unrar /usr/bin/unrar-alpine /usr/bin/unrar

# ports and volumes
EXPOSE 8112 58846 58946 58946/udp
VOLUME /config
