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
docker run --rm --user "$(id -u)":"$(id -g)" -v "$PWD":/app naoigcat/imagemagick identify image.png
```

It is recommended to create an alias:

```sh
alias imagemagick='docker run --rm --user "$(id -u)":"$(id -g)" -v "$PWD":/app naoigcat/imagemagick'
```

## Using in GitHub Actions

You can use this Docker image in your GitHub Actions workflows to process images during CI/CD.

### Basic Example

```yaml
name: Process Image

on: [push]

jobs:
  generate:
    runs-on: ubuntu-latest
    container:
      image: naoigcat/imagemagick:latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Create sample image
        run: magick -size 200x100 xc:white -gravity center -pointsize 24 -annotate 0 'Sample' output.jpg

      - name: Upload sample image
        uses: actions/upload-artifact@v4
        with:
          name: image
          path: output.jpg
```

### Using with docker run

Alternatively, you can use the image with `docker run` in your workflow:

```yaml
name: Process Image

on: [push]

jobs:
  process:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Create sample image
        run: |
          docker run --rm --user "$(id -u)":"$(id -g)" -v "$PWD":/app naoigcat/imagemagick \
            magick -size 200x100 xc:white -gravity center -pointsize 24 -annotate 0 'Sample' output.jpg

      - name: Upload sample image
        uses: actions/upload-artifact@v4
        with:
          name: image
          path: output.jpg
```
