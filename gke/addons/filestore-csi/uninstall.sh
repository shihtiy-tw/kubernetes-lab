#!/usr/bin/env bash
set -euo pipefail
PROJECT=""; CLUSTER=""; LOCATION=""; FORCE=false; DRY_RUN=false
while [[ $# -gt 0 ]]; do case "$1" in --project) PROJECT="$2"; shift 2 ;; --cluster) CLUSTER="$2"; shift 2 ;; --location) LOCATION="$2"; shift 2 ;; --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") --project PROJECT --cluster CLUSTER --location LOCATION [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ -z "$PROJECT" || -z "$CLUSTER" || -z "$LOCATION" ]] && { echo "All arguments required"; exit 1; }
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Disable Filestore CSI? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
run_cmd "gcloud container clusters update $CLUSTER --location=$LOCATION --update-addons=GcpFilestoreCsiDriver=DISABLED --project=$PROJECT"
echo "Filestore CSI driver disabled!"
