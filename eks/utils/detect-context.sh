#!/bin/bash
# =============================================================================
# detect-context.sh - Auto-detect EKS Cluster Context
# =============================================================================
#
# This script inspects the current kubectl context to identify the active
# EKS cluster, then queries AWS to retrieve version and status.
#
# Usage:
#   source detect-context.sh
#   detect_context
#
# Exports:
#   EKS_CLUSTER_NAME
#   EKS_CLUSTER_REGION
#   CLUSTER_VERSION
#   CLUSTER_STATUS
#   VPC_ID
#
# =============================================================================

# ANSI color codes for logging (if not already defined)
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[OK]${NC} $*" >&2; }

detect_context() {
    log_info "Attempting to auto-detect cluster context..."

    # 1. Get current context name
    local current_context
    current_context=$(kubectl config current-context 2>/dev/null)

    if [[ -z "$current_context" ]]; then
        log_warn "No active kubectl context found."
        return 1
    fi

    # 2. Extract Cluster ARN/Name from context
    # Usually EKS context names are like: arn:aws:eks:region:account:cluster/name
    # Or simple names if renamed. We'll try to find the cluster name associated with the context.

    local cluster_arn
    cluster_arn=$(kubectl config view --minify --output 'jsonpath={.clusters[0].name}' 2>/dev/null)

    # Handle ARN format: arn:aws:eks:us-east-1:123456789012:cluster/EKS-Lab-1-33-minimal
    if [[ "$cluster_arn" == arn:aws:eks:* ]]; then
        # Extract Region
        export EKS_CLUSTER_REGION=$(echo "$cluster_arn" | cut -d':' -f4)
        # Extract Cluster Name (everything after 'cluster/')
        export EKS_CLUSTER_NAME=$(echo "$cluster_arn" | cut -d'/' -f2)
    else
        # Fallback: assume the context name IS the cluster name or we can't easily parse it
        # We'll try to use it as the name, but warn.
        export EKS_CLUSTER_NAME="$cluster_arn"
        # Try to guess region from aws config if not explicit
        export EKS_CLUSTER_REGION=$(aws configure get region)
    fi

    if [[ -z "$EKS_CLUSTER_NAME" ]]; then
        log_error "Could not determine cluster name from context."
        return 1
    fi

    log_info "Detected Context: $EKS_CLUSTER_NAME ($EKS_CLUSTER_REGION)"

    # 3. Query AWS for precise details (Version, Status)
    local cluster_info
    cluster_info=$(aws eks describe-cluster \
        --name "$EKS_CLUSTER_NAME" \
        --region "$EKS_CLUSTER_REGION" \
        --query "cluster.{Version:version, Status:status, VpcId:resourcesVpcConfig.vpcId}" \
        --output json 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        log_error "Failed to describe cluster '$EKS_CLUSTER_NAME' in '$EKS_CLUSTER_REGION'. Check credentials or arguments."
        return 1
    fi

    export CLUSTER_VERSION=$(echo "$cluster_info" | jq -r '.Version')
    export CLUSTER_STATUS=$(echo "$cluster_info" | jq -r '.Status')
    export VPC_ID=$(echo "$cluster_info" | jq -r '.VpcId')

    log_success "Verified Cluster: $EKS_CLUSTER_NAME (v$CLUSTER_VERSION) [$CLUSTER_STATUS]"

    return 0
}
