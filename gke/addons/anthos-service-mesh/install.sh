#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; PROJECT=""; CLUSTER=""; LOCATION=""; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
usage() { echo "Usage: $(basename "$0") --project PROJECT --cluster CLUSTER --location LOCATION [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --project) PROJECT="$2"; shift 2 ;; --cluster) CLUSTER="$2"; shift 2 ;; --location) LOCATION="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; *) shift ;; esac; done
[[ -z "$PROJECT" || -z "$CLUSTER" || -z "$LOCATION" ]] && { echo "All arguments required"; usage; exit 1; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Enabling Anthos Service Mesh on GKE..."
run_cmd "gcloud container fleet mesh enable --project=$PROJECT"
run_cmd "gcloud container fleet memberships register $CLUSTER --gke-cluster=$LOCATION/$CLUSTER --project=$PROJECT" || true
run_cmd "gcloud container fleet mesh update --management automatic --memberships $CLUSTER --project=$PROJECT"
log_info "Anthos Service Mesh enabled!"
