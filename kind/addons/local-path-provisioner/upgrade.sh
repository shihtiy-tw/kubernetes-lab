#!/usr/bin/env bash
set -euo pipefail
run_cmd() { [[ "${DRY_RUN:-false}" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
echo "Re-applying latest manifest..."
run_cmd "kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml"
echo "local-path-provisioner upgraded!"
