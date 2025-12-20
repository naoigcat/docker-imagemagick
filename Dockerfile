FROM debian:bullseye-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive

ARG IM_VERSION=7.1.1-44
ARG IM_TARBALL_SHA256=c7cae9f885a995750909ee2ad79ea1f66a6a353f0c6da7b688aa4850aa1c26df

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

FROM debian:bullseye-slim
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

COPY --from=builder /usr/local/ /usr/local/
RUN ldconfig

WORKDIR /app
