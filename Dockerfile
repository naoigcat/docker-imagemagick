FROM debian:bullseye-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        clang \
        curl \
        fonts-dejavu \
        fonts-noto \
        ghostscript \
        libgomp1 \
        make \
        pkg-config \
        libfreetype6-dev \
        libfreetype6 \
        libheif-dev \
        libheif1 \
        libjbig-dev \
        libjbig0 \
        libjpeg62-turbo-dev \
        libjpeg62-turbo \
        libpng-dev \
        libpng16-16 \
        libtiff-dev \
        libtiff5 \
        libwebp-dev \
        libwebp6 \
        libwebpdemux2 \
        libwebpmux3 \
        libx11-dev \
        libx11-6 \
        libxml2-dev \
        libxml2 \
    && \
    curl -fsSL https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.1-11.tar.gz | \
    tar zx --strip-components 1 -C /tmp && \
    cd /tmp && \
    ./configure --without-magick-plus-plus --disable-docs --disable-static && \
    make && \
    make install && \
    ldconfig /usr/local/lib && \
    apt-get remove --autoremove --purge -y \
        ca-certificates \
        clang \
        curl \
        make \
        libfreetype6-dev \
        libheif-dev \
        libjbig-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libtiff-dev \
        libwebp-dev \
        libxml2-dev \
    && \
    apt-get clean && \
    rm -rf /tmp/* /var/cache/apt/archives/* /var/lib/apt/lists/*
WORKDIR /app
