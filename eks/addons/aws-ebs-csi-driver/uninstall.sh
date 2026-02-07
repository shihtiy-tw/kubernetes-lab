#!/usr/bin/env bash
set -euo pipefail
CLUSTER_NAME=""; FORCE=false; DRY_RUN=false
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
while [[ $# -gt 0 ]]; do case "$1" in --cluster) CLUSTER_NAME="$2"; shift 2 ;; --force) FORCE=true; shift ;; --dry-run) DRY_RUN=true; shift ;; --help) echo "Usage: $(basename "$0") --cluster NAME [--force] [--dry-run]"; exit 0 ;; *) shift ;; esac; done
[[ -z "$CLUSTER_NAME" ]] && { echo "Cluster name required"; exit 1; }
[[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]] && { read -rp "Uninstall EBS CSI Driver? (yes/no): " c; [[ "$c" != "yes" ]] && exit 0; }
run_cmd "aws eks delete-addon --cluster-name $CLUSTER_NAME --addon-name aws-ebs-csi-driver" || true
echo "AWS EBS CSI Driver uninstalled!"
