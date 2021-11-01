#!/usr/bin/env bash
set -e

export TAG=${TAG:=$(git rev-parse HEAD)}
infra/run-docker.sh
infra/render.sh
kubectl apply -f infra/dist/manifests.yaml --validate=true
