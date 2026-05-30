# syntax=docker/dockerfile:1
FROM debian:bullseye-slim@sha256:cd1bc32f233a49f1b82149c9edb8ef34fb1e6c45f37211445c51a97603468604 AS builder
ENV DEBIAN_FRONTEND=noninteractive

ARG IM_VERSION=7.1.2-24
ARG IM_TARBALL_SHA256=645f1dc68482ba952a02a854ffaf67efca42871b168e0cf702a043db2ec54638

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
RUN set -eux; \
    policy_file=/usr/local/etc/ImageMagick-7/policy.xml; \
    tmp_file="$(mktemp)"; \
    awk ' \
        /<\/policymap>/ { \
            print "  <!-- Keep upstream hardening and add container-specific limits for untrusted input. -->"; \
            print "  <policy domain=\"resource\" name=\"memory\" value=\"512MiB\"/>"; \
            print "  <policy domain=\"resource\" name=\"map\" value=\"1GiB\"/>"; \
            print "  <policy domain=\"resource\" name=\"disk\" value=\"2GiB\"/>"; \
            print "  <policy domain=\"resource\" name=\"area\" value=\"128MP\"/>"; \
            print "  <policy domain=\"resource\" name=\"time\" value=\"120\"/>"; \
            print "  <policy domain=\"resource\" name=\"thread\" value=\"4\"/>"; \
            print "  <policy domain=\"path\" rights=\"none\" pattern=\"@*\"/>"; \
            print "  <policy domain=\"delegate\" rights=\"none\" pattern=\"URL\"/>"; \
            print "  <policy domain=\"delegate\" rights=\"none\" pattern=\"HTTP\"/>"; \
            print "  <policy domain=\"delegate\" rights=\"none\" pattern=\"HTTPS\"/>"; \
            print "  <policy domain=\"coder\" rights=\"none\" pattern=\"PDF\"/>"; \
            print "  <policy domain=\"coder\" rights=\"none\" pattern=\"PS\"/>"; \
            print "  <policy domain=\"coder\" rights=\"none\" pattern=\"PS2\"/>"; \
            print "  <policy domain=\"coder\" rights=\"none\" pattern=\"PS3\"/>"; \
            print "  <policy domain=\"coder\" rights=\"none\" pattern=\"EPS\"/>"; \
            print "  <policy domain=\"coder\" rights=\"none\" pattern=\"XPS\"/>"; \
        } \
        { print } \
    ' "$policy_file" > "$tmp_file"; \
    install -m 0644 "$tmp_file" "$policy_file"; \
    rm "$tmp_file"
RUN ldconfig

ENV HOME=/home/imagemagick
WORKDIR /app
USER imagemagick:imagemagick
