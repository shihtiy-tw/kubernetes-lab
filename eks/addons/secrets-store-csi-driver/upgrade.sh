#!/usr/bin/env bash
set -euo pipefail
NS="kube-system"; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--dry-run]"; exit 0 ;; *) shift ;; esac; done
run_cmd "helm repo update"
run_cmd "helm upgrade secrets-store-csi-driver secrets-store-csi-driver/secrets-store-csi-driver -n $NS"
run_cmd "helm upgrade secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws -n $NS"
echo "Secrets Store CSI Driver upgraded!"
