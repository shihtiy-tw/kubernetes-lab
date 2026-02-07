#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; NAMESPACE="metallb-system"; IP_RANGE=""; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
usage() { echo "Usage: $(basename "$0") --ip-range START-END [--namespace NS] [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --ip-range) IP_RANGE="$2"; shift 2 ;; --namespace) NAMESPACE="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; *) shift ;; esac; done
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Installing MetalLB..."
run_cmd "kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml"
log_info "Waiting for controller..."
run_cmd "kubectl wait --namespace $NAMESPACE --for=condition=ready pod --selector=app=metallb --timeout=90s" || true
if [[ -n "$IP_RANGE" ]]; then
    log_info "Configuring IP pool..."
    cat << EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: $NAMESPACE
spec:
  addresses:
  - $IP_RANGE
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: $NAMESPACE
EOF
fi
log_info "MetalLB installed!"
