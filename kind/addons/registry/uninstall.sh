#!/usr/bin/env bash
set -euo pipefail
REGISTRY_NAME="kind-registry"; FORCE=false; DRY_RUN=false
while [[ $# -gt 0 ]]; do case "$1" in --name) REGISTRY_NAME="$2"; shift 2 ;; --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--name NAME] [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Uninstall registry $REGISTRY_NAME? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
run_cmd "kubectl delete configmap local-registry-hosting -n kube-public --ignore-not-found"
run_cmd "docker stop $REGISTRY_NAME" || true
run_cmd "docker rm $REGISTRY_NAME" || true
echo "Registry uninstalled!"
