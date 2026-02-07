#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; CLUSTER_NAME=""; DRY_RUN=false
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
usage() { echo "Usage: $(basename "$0") --cluster NAME [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --cluster) CLUSTER_NAME="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; --script-version) echo "v$VERSION"; exit 0 ;; *) shift ;; esac; done
[[ -z "$CLUSTER_NAME" ]] && { log_error "Cluster name required (--cluster)"; exit 1; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Installing AWS EBS CSI Driver as EKS addon..."
cmd="aws eks create-addon --cluster-name $CLUSTER_NAME --addon-name aws-ebs-csi-driver --resolve-conflicts OVERWRITE"
run_cmd "$cmd" || log_info "Addon may already exist, attempting update..."
run_cmd "aws eks update-addon --cluster-name $CLUSTER_NAME --addon-name aws-ebs-csi-driver --resolve-conflicts OVERWRITE" || true
log_info "AWS EBS CSI Driver installed!"
log_info "NOTE: Ensure IRSA is configured with AmazonEBSCSIDriverPolicy"
