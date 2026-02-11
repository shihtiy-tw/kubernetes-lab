#!/usr/bin/env bash
set -euo pipefail
NS="external-secrets"; RN="external-secrets"; FORCE=false; DELETE_CRDS=false; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --force) FORCE=true; shift ;; --delete-crds) DELETE_CRDS=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--force] [--delete-crds] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Uninstall external-secrets? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd "helm uninstall $RN -n $NS" || true
[[ "$DELETE_CRDS" == "true" ]] && run_cmd "kubectl delete crd externalsecrets.external-secrets.io secretstores.external-secrets.io clustersecretstores.external-secrets.io" || true
run_cmd "kubectl delete namespace $NS --ignore-not-found"
echo "external-secrets uninstalled!"
