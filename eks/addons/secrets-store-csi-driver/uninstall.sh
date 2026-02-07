#!/usr/bin/env bash
set -euo pipefail
NS="kube-system"; FORCE=false; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Uninstall Secrets Store CSI? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd "helm uninstall secrets-provider-aws -n $NS" || true
run_cmd "helm uninstall secrets-store-csi-driver -n $NS" || true
echo "Secrets Store CSI Driver uninstalled!"
