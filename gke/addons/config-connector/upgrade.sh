#!/usr/bin/env bash
set -euo pipefail
DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--dry-run]"; exit 0 ;; *) shift ;; esac; done
run_cmd "kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-config-connector/master/install-bundles/install-bundle-workload-identity/install-bundle.yaml"
echo "Config Connector upgraded!"
