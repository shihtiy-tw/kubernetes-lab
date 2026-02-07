#!/usr/bin/env bash
set -euo pipefail
REGISTRY_NAME="kind-registry"
while [[ $# -gt 0 ]]; do case "$1" in --name) REGISTRY_NAME="$2"; shift 2 ;; *) shift ;; esac; done
docker pull registry:2
docker stop "$REGISTRY_NAME" || true
docker rm "$REGISTRY_NAME" || true
docker run -d --restart=always -p 127.0.0.1:5001:5000 --name "$REGISTRY_NAME" registry:2
docker network connect kind "$REGISTRY_NAME" || true
echo "Registry upgraded to latest!"
