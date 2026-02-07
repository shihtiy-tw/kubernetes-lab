#!/usr/bin/env bash
set -euo pipefail
NS="kube-system"; RN="aad-pod-identity"; FORCE=false; DELETE_CRDS=false; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --force) FORCE=true; shift ;; --delete-crds) DELETE_CRDS=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--force] [--delete-crds] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Uninstall AAD Pod Identity? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd "helm uninstall $RN -n $NS" || true
[[ "$DELETE_CRDS" == "true" ]] && run_cmd "kubectl delete crd azureidentities.aadpodidentity.k8s.io azureidentitybindings.aadpodidentity.k8s.io azurepodidentityexceptions.aadpodidentity.k8s.io" || true
echo "AAD Pod Identity uninstalled!"
