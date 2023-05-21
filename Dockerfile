FROM ghcr.io/linuxserver/baseimage-alpine:3.17

ARG UNRAR_VERSION=6.1.7
# set version label
ARG BUILD_DATE
ARG VERSION
ARG DELUGE_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment variables
ENV PYTHON_EGG_CACHE="/config/plugins/.python-eggs"

ENV FILEBOT_VERSION 4.7.19.3
ENV FILEBOT_URL https://github.com/bigoulours/filebot/releases/download/$FILEBOT_VERSION/FileBot_$FILEBOT_VERSION-portable.tar.gz

# install software
RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --upgrade --virtual=build-dependencies \
    make \
    g++ \
    gcc \
    python3-dev && \
  echo "**** install packages ****" && \
  apk add --no-cache --upgrade --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    python3 \
    py3-geoip \
    p7zip && \
  echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" && \
  tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1 && \
  cd /tmp/unrar && \
  make && \
  install -v -m755 unrar /usr/local/bin && \
  apk add -U --upgrade --no-cache \
    deluge && \  
  echo "**** install python packages ****" && \
  python3 -m ensurepip && \
  pip3 install -U --no-cache-dir \
    pip \
    wheel && \
  pip3 install --no-cache-dir \
    future \
    requests && \
  echo "**** grab GeoIP database ****" && \
  curl -o \
    /usr/share/GeoIP/GeoIP.dat -L --retry 10 --retry-max-time 60 --retry-all-errors \
    "https://infura-ipfs.io/ipfs/QmWTWcPRRbADZcLcJeANZmcJZNrcpmuQgKYBi6hGdddtC6" && \
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
    openjdk16-jre \
    libmediainfo \
    && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8112 58846 58946 58946/udp
VOLUME /config
