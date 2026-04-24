FROM debian:bullseye-slim@sha256:1a4701c321b1d28b1ff5f0230e766791e4b79b1d4c6c7a70064f4b297b1a330f AS builder
ENV DEBIAN_FRONTEND=noninteractive

ARG IM_VERSION=7.1.2-21
ARG IM_TARBALL_SHA256=4ba5b81797910efa93e65fb5a02b496284b8069d64513c6d2687c80d180dd70f

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

FROM debian:bullseye-slim@sha256:1a4701c321b1d28b1ff5f0230e766791e4b79b1d4c6c7a70064f4b297b1a330f
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
RUN ldconfig

ENV HOME=/home/imagemagick
WORKDIR /app
USER imagemagick:imagemagick
