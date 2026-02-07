#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; REGISTRY_NAME="kind-registry"; REGISTRY_PORT="5001"; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
usage() { echo "Usage: $(basename "$0") [--name NAME] [--port PORT] [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --name) REGISTRY_NAME="$2"; shift 2 ;; --port) REGISTRY_PORT="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; *) shift ;; esac; done
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
if ! docker inspect "$REGISTRY_NAME" &>/dev/null; then
    log_info "Creating local registry container..."
    run_cmd "docker run -d --restart=always -p 127.0.0.1:${REGISTRY_PORT}:5000 --name $REGISTRY_NAME registry:2"
fi
log_info "Connecting registry to kind network..."
run_cmd "docker network connect kind $REGISTRY_NAME" || true
log_info "Creating ConfigMap for registry..."
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
log_info "Registry installed at localhost:${REGISTRY_PORT}!"
