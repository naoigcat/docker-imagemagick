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
name: Process Images

on: [push]

jobs:
  convert:
    runs-on: ubuntu-latest
    container:
      image: naoigcat/imagemagick:latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Convert image
        run: convert input.png output.jpg
      
      - name: Get image info
        run: identify output.jpg
```

### Using with docker run

Alternatively, you can use the image with `docker run` in your workflow:

```yaml
name: Image Processing

on: [push]

jobs:
  process:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Convert image
        run: |
          docker run --rm -v "$PWD":/app naoigcat/imagemagick \
            convert input.png -resize 800x600 output.jpg
      
      - name: Upload processed images
        uses: actions/upload-artifact@v4
        with:
          name: processed-images
          path: output.jpg
```

### Example: Batch Image Processing

```yaml
name: Batch Convert

on: [push]

jobs:
  batch-convert:
    runs-on: ubuntu-latest
    container:
      image: naoigcat/imagemagick:latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Batch convert PNG to JPG
        run: |
          shopt -s nullglob
          for file in *.png; do
            convert "$file" "${file%.png}.jpg"
          done
      
      - name: Create thumbnails
        run: |
          shopt -s nullglob
          mkdir -p thumbnails
          for file in *.jpg; do
            convert "$file" -resize 200x200 "thumbnails/$file"
          done
```
