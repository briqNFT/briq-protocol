#!/usr/bin/env bash
set -e

TAG=${TAG:=$(git rev-parse HEAD)}

mkdir -p infra/dist
ytt -f infra/schema.yaml -f infra/ --data-value "image_tag=$TAG" > infra/dist/manifests.yaml
echo "validating client-side"
kubectl apply -f infra/dist/manifests.yaml --validate=true --dry-run=client
echo "validating server-side"
kubectl apply -f infra/dist/manifests.yaml --validate=true --dry-run=server
