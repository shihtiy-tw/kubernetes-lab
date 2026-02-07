#!/usr/bin/env bash
set -euo pipefail
CLUSTER=""; RESOURCE_GROUP=""; FORCE=false; DRY_RUN=false
while [[ $# -gt 0 ]]; do case "$1" in --cluster) CLUSTER="$2"; shift 2 ;; --resource-group) RESOURCE_GROUP="$2"; shift 2 ;; --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") --cluster CLUSTER --resource-group RG [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ -z "$CLUSTER" || -z "$RESOURCE_GROUP" ]] && { echo "All arguments required"; exit 1; }
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Disable Azure Policy? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
run_cmd "az aks disable-addons --addons azure-policy --name $CLUSTER --resource-group $RESOURCE_GROUP"
echo "Azure Policy addon disabled!"
