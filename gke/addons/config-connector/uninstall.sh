#!/usr/bin/env bash
set -euo pipefail
FORCE=false; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Uninstall Config Connector? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd "kubectl delete configconnector.core.cnrm.cloud.google.com --all" || true
run_cmd "kubectl delete -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-config-connector/master/install-bundles/install-bundle-workload-identity/install-bundle.yaml" || true
echo "Config Connector uninstalled!"
