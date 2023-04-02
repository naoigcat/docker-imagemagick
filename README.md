# Docker ImageMagick

[![Docker Builds](https://github.com/naoigcat/docker-imagemagick/actions/workflows/push.yml/badge.svg)](https://github.com/naoigcat/docker-imagemagick/actions/workflows/push.yml)

[![GitHub Stars](https://img.shields.io/github/stars/naoigcat/docker-imagemagick.svg)](https://github.com/naoigcat/docker-imagemagick/stargazers)
[![Docker Pulls](https://img.shields.io/docker/pulls/naoigcat/imagemagick)](https://hub.docker.com/r/naoigcat/imagemagick)

**Docker Image for [ImageMagick](https://imagemagick.org/index.php)**

## Installation

```sh
docker pull naoigcat/imagemagick
```

## Usage

See [imagemagick](https://imagemagick.org/index.php) for available commands.

```sh
docker run --rm -v \"$PWD\":/app naoigcat/imagemagick identify image.png
```

It is recommended to create an alias:

```sh
alias imagemagick="docker run --rm -v \"$PWD\":/app naoigcat/imagemagick"
```
