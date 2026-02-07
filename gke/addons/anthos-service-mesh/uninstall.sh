#!/usr/bin/env bash
set -euo pipefail
PROJECT=""; CLUSTER=""; FORCE=false; DRY_RUN=false
while [[ $# -gt 0 ]]; do case "$1" in --project) PROJECT="$2"; shift 2 ;; --cluster) CLUSTER="$2"; shift 2 ;; --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") --project PROJECT --cluster CLUSTER [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ -z "$PROJECT" || -z "$CLUSTER" ]] && { echo "All arguments required"; exit 1; }
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Disable ASM? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
run_cmd "gcloud container fleet mesh update --management manual --memberships $CLUSTER --project=$PROJECT"
echo "ASM management set to manual. Fully removing requires fleet membership deletion."
