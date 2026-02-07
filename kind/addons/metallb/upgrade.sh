#!/usr/bin/env bash
set -euo pipefail
run_cmd() { [[ "${DRY_RUN:-false}" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
echo "Re-applying latest manifest..."
run_cmd "kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml"
echo "MetalLB upgraded!"
