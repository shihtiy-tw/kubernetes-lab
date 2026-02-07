#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; CLUSTER=""; RESOURCE_GROUP=""; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
usage() { echo "Usage: $(basename "$0") --cluster CLUSTER --resource-group RG [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --cluster) CLUSTER="$2"; shift 2 ;; --resource-group) RESOURCE_GROUP="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; *) shift ;; esac; done
[[ -z "$CLUSTER" || -z "$RESOURCE_GROUP" ]] && { echo "All arguments required"; usage; exit 1; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Enabling Azure File CSI driver on AKS..."
run_cmd "az aks update --name $CLUSTER --resource-group $RESOURCE_GROUP --enable-file-driver"
log_info "Azure File CSI driver enabled!"
