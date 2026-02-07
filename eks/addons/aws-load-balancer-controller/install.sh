#!/usr/bin/env bash
set -euo pipefail
VERSION="1.0.0"; CLUSTER_NAME=""; NAMESPACE="kube-system"; RELEASE_NAME="aws-load-balancer-controller"; CHART_VERSION=""; DRY_RUN=false
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
usage() { cat << EOF
Usage: $(basename "$0") [OPTIONS]
Install AWS Load Balancer Controller.
Required: --cluster CLUSTER
Optional: --namespace NS, --version VER, --dry-run, --help
EOF
}
while [[ $# -gt 0 ]]; do case "$1" in --cluster) CLUSTER_NAME="$2"; shift 2 ;; --namespace) NAMESPACE="$2"; shift 2 ;; --version) CHART_VERSION="$2"; shift 2 ;; --dry-run) DRY_RUN=true; shift ;; --help) usage; exit 0 ;; --script-version) echo "v$VERSION"; exit 0 ;; *) shift ;; esac; done
[[ -z "$CLUSTER_NAME" ]] && { log_error "Cluster name required (--cluster)"; usage; exit 1; }
run_cmd() { [[ "$DRY_RUN" == "true" ]] && echo "[DRY RUN] $*" || eval "$@"; }

log_info "Adding Helm repo..."
run_cmd "helm repo add eks https://aws.github.io/eks-charts --force-update"
run_cmd "helm repo update eks"

log_info "Installing AWS Load Balancer Controller..."
cmd="helm upgrade --install $RELEASE_NAME eks/aws-load-balancer-controller -n $NAMESPACE"
cmd="$cmd --set clusterName=$CLUSTER_NAME"
cmd="$cmd --set serviceAccount.create=true"
cmd="$cmd --set serviceAccount.name=aws-load-balancer-controller"
[[ -n "$CHART_VERSION" ]] && cmd="$cmd --version $CHART_VERSION"
run_cmd "$cmd"
log_info "AWS Load Balancer Controller installed!"
log_info "NOTE: Ensure IRSA is configured for the service account with appropriate IAM policy"
