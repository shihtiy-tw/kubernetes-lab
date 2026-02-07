#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; CLUSTER_NAME=""; NAMESPACE="kube-system"; RELEASE_NAME="cluster-autoscaler"; CHART_VERSION=""; AWS_REGION=""; DRY_RUN=false
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
usage() { echo "Usage: $(basename "$0") --cluster NAME --region REGION [--namespace NS] [--version VER] [--dry-run]"; }
while [[ $# -gt 0 ]]; do case "$1" in --cluster) CLUSTER_NAME="$2"; shift 2 ;; --region) AWS_REGION="$2"; shift 2 ;; --namespace) NAMESPACE="$2"; shift 2 ;; --version) CHART_VERSION="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; --script-version) echo "v$VERSION"; exit 0 ;; *) shift ;; esac; done
[[ -z "$CLUSTER_NAME" ]] && { log_error "Cluster name required (--cluster)"; exit 1; }
[[ -z "$AWS_REGION" ]] && AWS_REGION=$(aws configure get region)
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }
log_info "Adding Helm repo..."
run_cmd "helm repo add autoscaler https://kubernetes.github.io/autoscaler --force-update"
run_cmd "helm repo update autoscaler"
log_info "Installing Cluster Autoscaler..."
cmd="helm upgrade --install $RELEASE_NAME autoscaler/cluster-autoscaler -n $NAMESPACE"
cmd="$cmd --set autoDiscovery.clusterName=$CLUSTER_NAME"
cmd="$cmd --set awsRegion=$AWS_REGION"
[[ -n "$CHART_VERSION" ]] && cmd="$cmd --version $CHART_VERSION"
run_cmd "$cmd"
log_info "Cluster Autoscaler installed!"
