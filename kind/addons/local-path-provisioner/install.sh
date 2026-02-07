#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
while [[ $# -gt 0 ]]; do case "$1" in --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--dry-run]"; exit 0 ;; *) shift ;; esac; done
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Installing local-path-provisioner for Kind..."
run_cmd "kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml"
log_info "Setting as default StorageClass..."
run_cmd "kubectl patch storageclass local-path -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'"
log_info "local-path-provisioner installed!"
