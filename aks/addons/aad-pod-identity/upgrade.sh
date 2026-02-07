#!/usr/bin/env bash
set -euo pipefail
NS="kube-system"; RN="aad-pod-identity"; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--dry-run]"; exit 0 ;; *) shift ;; esac; done
helm status "$RN" -n "$NS" &>/dev/null || { echo "Not installed"; exit 1; }
run_cmd "helm repo update aad-pod-identity"
run_cmd "helm upgrade $RN aad-pod-identity/aad-pod-identity -n $NS"
echo "AAD Pod Identity upgraded!"
