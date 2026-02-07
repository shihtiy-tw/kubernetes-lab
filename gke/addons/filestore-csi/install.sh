#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; PROJECT=""; CLUSTER=""; LOCATION=""; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
usage() { echo "Usage: $(basename "$0") --project PROJECT --cluster CLUSTER --location LOCATION [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --project) PROJECT="$2"; shift 2 ;; --cluster) CLUSTER="$2"; shift 2 ;; --location) LOCATION="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; *) shift ;; esac; done
[[ -z "$PROJECT" || -z "$CLUSTER" || -z "$LOCATION" ]] && { echo "All arguments required"; usage; exit 1; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Enabling Filestore CSI driver on GKE cluster..."
run_cmd "gcloud container clusters update $CLUSTER --location=$LOCATION --update-addons=GcpFilestoreCsiDriver=ENABLED --project=$PROJECT"
log_info "Filestore CSI driver enabled!"
