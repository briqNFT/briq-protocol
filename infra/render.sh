#!/usr/bin/env bash
set -e

TAG=${TAG:=$(git rev-parse HEAD)}

K8S_ENV=${K8S_ENV:="test"}

mkdir -p infra/dist
ytt -f infra/schema.yaml -f infra/vals-${K8S_ENV}.yaml -f infra/k8s/ --data-value "image_tag=$TAG" > infra/dist/manifests-${K8S_ENV}.yaml
echo "validating client-side"
kubectl apply -f infra/dist/manifests-${K8S_ENV}.yaml --validate=true --dry-run=client
echo "validating server-side"
kubectl apply -f infra/dist/manifests-${K8S_ENV}.yaml --validate=true --dry-run=server
