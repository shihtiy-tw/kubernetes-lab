#!/usr/bin/env bash
set -euo pipefail
CLUSTER_NAME=""; TO_VERSION=""; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --cluster) CLUSTER_NAME="$2"; shift 2 ;; --to-version) TO_VERSION="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") --cluster NAME [--to-version VER] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ -z "$CLUSTER_NAME" ]] && { echo "Cluster name required"; exit 1; }
cmd="aws eks update-addon --cluster-name $CLUSTER_NAME --addon-name aws-efs-csi-driver --resolve-conflicts OVERWRITE"
[[ -n "$TO_VERSION" ]] && cmd="$cmd --addon-version $TO_VERSION"
run_cmd "$cmd"
echo "AWS EFS CSI Driver upgraded!"
