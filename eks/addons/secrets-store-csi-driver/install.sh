#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; NAMESPACE="kube-system"; RELEASE_NAME="secrets-store-csi-driver"; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
usage() { echo "Usage: $(basename "$0") [--namespace NS] [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --namespace) NAMESPACE="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; *) shift ;; esac; done
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Adding Helm repos..."
run_cmd "helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts --force-update"
run_cmd "helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws --force-update"
run_cmd "helm repo update"
log_info "Installing Secrets Store CSI Driver..."
run_cmd "helm upgrade --install $RELEASE_NAME secrets-store-csi-driver/secrets-store-csi-driver -n $NAMESPACE --set syncSecret.enabled=true"
log_info "Installing AWS Provider..."
run_cmd "helm upgrade --install secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws -n $NAMESPACE"
log_info "Secrets Store CSI Driver installed!"
