FROM debian:bullseye-slim@sha256:cd1bc32f233a49f1b82149c9edb8ef34fb1e6c45f37211445c51a97603468604 AS builder
ENV DEBIAN_FRONTEND=noninteractive

ARG IM_VERSION=7.1.2-23
ARG IM_TARBALL_SHA256=f129f7d87fc21da453d032dd291b80ea13faf2497f13ef8279d97759ed7d5c46

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        build-essential \
        pkg-config \
        libfreetype6-dev \
        libheif-dev \
        libjbig-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libtiff-dev \
        libwebp-dev \
        libx11-dev \
        libxml2-dev \
    && \
    mkdir -p /tmp/imagemagick-src && \
    curl -fsSL "https://github.com/ImageMagick/ImageMagick/archive/refs/tags/${IM_VERSION}.tar.gz" -o /tmp/imagemagick.tar.gz && \
    echo "${IM_TARBALL_SHA256}  /tmp/imagemagick.tar.gz" | sha256sum -c - && \
    tar zx --strip-components 1 -C /tmp/imagemagick-src -f /tmp/imagemagick.tar.gz && \
    cd /tmp/imagemagick-src && \
    ./configure --without-magick-plus-plus --disable-docs --disable-static && \
    make -j"$(nproc)" && \
    make install && \
    ldconfig && \
    rm -rf /tmp/imagemagick-src /tmp/imagemagick.tar.gz && \
    rm -rf /var/lib/apt/lists/*

FROM debian:bullseye-slim@sha256:cd1bc32f233a49f1b82149c9edb8ef34fb1e6c45f37211445c51a97603468604
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        fonts-dejavu \
        fonts-noto \
        ghostscript \
        libgomp1 \
        libfreetype6 \
        libheif1 \
        libjbig0 \
        libjpeg62-turbo \
        libpng16-16 \
        libtiff5 \
        libwebp6 \
        libwebpdemux2 \
        libwebpmux3 \
        libx11-6 \
        libxml2 \
    && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 10001 imagemagick && \
    useradd --system --uid 10001 --gid imagemagick --create-home --home-dir /home/imagemagick imagemagick && \
    install -d -o imagemagick -g imagemagick /app

COPY --from=builder /usr/local/ /usr/local/
RUN cat > /usr/local/etc/ImageMagick-7/policy.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policymap [
<!ELEMENT policymap (policy)*>
<!ATTLIST policymap xmlns CDATA #FIXED ''>
<!ELEMENT policy EMPTY>
<!ATTLIST policy xmlns CDATA #FIXED '' domain NMTOKEN #REQUIRED
  name NMTOKEN #IMPLIED pattern CDATA #IMPLIED rights NMTOKEN #IMPLIED
  stealth NMTOKEN #IMPLIED value CDATA #IMPLIED>
]>
<policymap>
  <policy domain="resource" name="memory" value="512MiB"/>
  <policy domain="resource" name="map" value="1GiB"/>
  <policy domain="resource" name="disk" value="2GiB"/>
  <policy domain="resource" name="area" value="128MP"/>
  <policy domain="resource" name="time" value="120"/>
  <policy domain="resource" name="thread" value="4"/>
  <policy domain="path" rights="none" pattern="@*"/>
  <policy domain="delegate" rights="none" pattern="URL"/>
  <policy domain="delegate" rights="none" pattern="HTTP"/>
  <policy domain="delegate" rights="none" pattern="HTTPS"/>
</policymap>
EOF
RUN ldconfig

ENV HOME=/home/imagemagick
WORKDIR /app
USER imagemagick:imagemagick
