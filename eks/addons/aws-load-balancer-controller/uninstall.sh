#!/usr/bin/env bash
set -euo pipefail
NS="kube-system"; RN="aws-load-balancer-controller"; FORCE=false; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Uninstall AWS LB Controller? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd "helm uninstall $RN -n $NS" || true
echo "AWS Load Balancer Controller uninstalled!"
