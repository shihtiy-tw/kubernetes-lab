#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="ingress-nginx"; RELEASE_NAME="ingress-nginx"; TO_VERSION=""; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --to-version) TO_VERSION="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--to-version VER] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
helm status "$RELEASE_NAME" -n "$NAMESPACE" &>/dev/null || { echo "Not installed"; exit 1; }
run_cmd "helm repo update ingress-nginx"
cmd="helm upgrade $RELEASE_NAME ingress-nginx/ingress-nginx -n $NAMESPACE"
[[ -n "$TO_VERSION" ]] && cmd="$cmd --version $TO_VERSION"
run_cmd "$cmd"
echo "ingress-nginx upgraded!"
