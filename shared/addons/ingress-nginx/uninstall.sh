#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="ingress-nginx"; RELEASE_NAME="ingress-nginx"; FORCE=false; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Uninstall ingress-nginx? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd "helm uninstall $RELEASE_NAME -n $NAMESPACE" || true
run_cmd "kubectl delete namespace $NAMESPACE --ignore-not-found"
echo "ingress-nginx uninstalled!"
