#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; CLUSTER_NAME=""; NAMESPACE="karpenter"; CHART_VERSION=""; DRY_RUN=false
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
usage() { echo "Usage: $(basename "$0") --cluster NAME [--namespace NS] [--version VER] [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --cluster) CLUSTER_NAME="$2"; shift 2 ;; --namespace) NAMESPACE="$2"; shift 2 ;; --version) CHART_VERSION="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; --script-version) echo "v$VERSION"; exit 0 ;; *) shift ;; esac; done
[[ -z "$CLUSTER_NAME" ]] && { log_error "Cluster name required (--cluster)"; exit 1; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Adding Helm repo..."
run_cmd "helm repo add oci://public.ecr.aws/karpenter/karpenter --force-update" || true
log_info "Installing Karpenter..."
cmd="helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter -n $NAMESPACE --create-namespace"
cmd="$cmd --set settings.clusterName=$CLUSTER_NAME"
[[ -n "$CHART_VERSION" ]] && cmd="$cmd --version $CHART_VERSION"
run_cmd "$cmd"
log_info "Karpenter installed! Configure NodePool and EC2NodeClass resources."
