#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; PROJECT=""; POLICY_NAME=""; DRY_RUN=false
GREEN='\033[0;32m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
usage() { echo "Usage: $(basename "$0") --project PROJECT --policy-name NAME [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --project) PROJECT="$2"; shift 2 ;; --policy-name) POLICY_NAME="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; *) shift ;; esac; done
[[ -z "$PROJECT" || -z "$POLICY_NAME" ]] && { echo "All arguments required"; usage; exit 1; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Creating Cloud Armor security policy..."
run_cmd "gcloud compute security-policies create $POLICY_NAME --project=$PROJECT"
log_info "Adding default rules..."
run_cmd "gcloud compute security-policies rules create 2147483647 --security-policy=$POLICY_NAME --action=allow --src-ip-ranges='*' --project=$PROJECT"
log_info "Cloud Armor policy '$POLICY_NAME' created!"
log_info "Attach to backend service: gcloud compute backend-services update BACKEND --security-policy=$POLICY_NAME"
