#!/usr/bin/env bash
set -euo pipefail
PROJECT=""; POLICY_NAME=""; FORCE=false; DRY_RUN=false
while [[ $# -gt 0 ]]; do case "$1" in --project) PROJECT="$2"; shift 2 ;; --policy-name) POLICY_NAME="$2"; shift 2 ;; --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") --project PROJECT --policy-name NAME [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ -z "$PROJECT" || -z "$POLICY_NAME" ]] && { echo "All arguments required"; exit 1; }
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Delete Cloud Armor policy $POLICY_NAME? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
run_cmd "gcloud compute security-policies delete $POLICY_NAME --project=$PROJECT --quiet"
echo "Cloud Armor policy deleted!"
