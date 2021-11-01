#!/usr/bin/env bash
set -e

NAME="briq-protocol"
TAG=${TAG:=$(git rev-parse HEAD)}
echo "Building docker image, tagging $TAG"
IMAGE_NAME="europe-west3-docker.pkg.dev/healthy-saga-329513/sltech-briq/$NAME:$TAG"

docker build . -f infra/Dockerfile -t "$IMAGE_NAME"
docker push "$IMAGE_NAME"
# Tag the image as 'latest' locally
docker tag "$IMAGE_NAME" "$NAME:latest"
# Cleanup
docker image rm "$IMAGE_NAME"