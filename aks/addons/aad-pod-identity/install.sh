#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; NAMESPACE="kube-system"; RELEASE_NAME="aad-pod-identity"; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
usage() { echo "Usage: $(basename "$0") [--namespace NS] [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --namespace) NAMESPACE="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; *) shift ;; esac; done
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Adding Helm repo..."
run_cmd "helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts --force-update"
run_cmd "helm repo update aad-pod-identity"
log_info "Installing AAD Pod Identity..."
cmd="helm upgrade --install $RELEASE_NAME aad-pod-identity/aad-pod-identity -n $NAMESPACE"
run_cmd "$cmd"
log_info "AAD Pod Identity installed! Create AzureIdentity and AzureIdentityBinding resources."
