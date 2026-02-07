#!/usr/bin/env bash
set -euo pipefail
FORCE=false; DRY_RUN=false
while [[ $# -gt 0 ]]; do case "$1" in --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Uninstall local-path-provisioner? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
run_cmd "kubectl delete -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml --ignore-not-found"
echo "local-path-provisioner uninstalled!"
