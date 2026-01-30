#!/usr/bin/env bash
# Karpenter General Configuration Scenario
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Configure Karpenter NodePool and EC2NodeClass resources.

OPTIONS:
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --nodepool FILE       NodePool YAML file (default: nodepool.yaml)
    --nodeclass FILE      EC2NodeClass YAML file (default: nodeclass.yaml)
    --dry-run             Show what would be applied
    --delete              Delete the Karpenter resources
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Apply configuration
    $(basename "$0")

    # Dry run
    $(basename "$0") --dry-run

    # Delete resources
    $(basename "$0") --delete

    # Use custom files
    $(basename "$0") --nodepool custom-nodepool.yaml --nodeclass custom-nodeclass.yaml
EOF
}

show_version() {
    echo "$(basename "$0") version ${SCRIPT_VERSION}"
}

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&1; }
log_success() { echo -e "${GREEN}[OK]${NC} $*" >&1; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "\n${YELLOW}=== $* ===${NC}" >&1; }

# Defaults
CLUSTER_NAME=""
REGION=""
NODEPOOL_FILE="nodepool.yaml"
NODECLASS_FILE="nodeclass.yaml"
DRY_RUN=false
DELETE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --nodepool)
            NODEPOOL_FILE="$2"
            shift 2
            ;;
        --nodeclass)
            NODECLASS_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --delete)
            DELETE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Run '$(basename "$0") --help' for usage." >&2
            exit 1
            ;;
    esac
done

# Get cluster info
get_cluster_info() {
    if [[ -z "$CLUSTER_NAME" ]] || [[ -z "$REGION" ]]; then
        local context
        context=$(kubectl config current-context)
        
        [[ -z "$CLUSTER_NAME" ]] && CLUSTER_NAME=$(echo "$context" | awk -F: '{split($NF,a,"/"); print a[2]}')
        [[ -z "$REGION" ]] && REGION=$(echo "$context" | awk -F: '{print $4}')
    fi
    
    # Export for envsubst
    export EKS_CLUSTER_NAME="$CLUSTER_NAME"
    export CLUSTER_VERSION
    CLUSTER_VERSION=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query 'cluster.version' --output text)
    
    # Get AL2 AMI alias
    export ALIAS
    ALIAS=$(aws ssm get-parameters-by-path \
        --path "/aws/service/eks/optimized-ami/$CLUSTER_VERSION/amazon-linux-2/" \
        --recursive 2>/dev/null | \
        jq -cr '.Parameters[].Name' | \
        grep -v "recommended" | \
        awk -F '/' '{print $8}' | \
        sed -r 's/.*(v[[:digit:]]+)$/\1/' | \
        sort -r | uniq | head -n 1 || echo "")
}

# Delete resources
delete_resources() {
    log_step "Deleting Karpenter Resources"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would delete NodePool from: $NODEPOOL_FILE"
        log_info "[DRY RUN] Would delete EC2NodeClass from: $NODECLASS_FILE"
        exit 0
    fi
    
    cd "$SCRIPT_DIR"
    
    if [[ -f "$NODEPOOL_FILE" ]]; then
        envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${ALIAS}' < "$NODEPOOL_FILE" | kubectl delete -f - 2>/dev/null || true
    fi
    
    if [[ -f "$NODECLASS_FILE" ]]; then
        envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${ALIAS}' < "$NODECLASS_FILE" | kubectl delete -f - 2>/dev/null || true
    fi
    
    log_success "Resources deleted"
    exit 0
}

# Main
main() {
    get_cluster_info
    
    if $DELETE; then
        delete_resources
    fi

    log_step "Environment"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Version: $CLUSTER_VERSION"
    log_info "Region: $REGION"
    log_info "AL2 Alias: $ALIAS"

    cd "$SCRIPT_DIR"

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would apply NodePool from: $NODEPOOL_FILE"
        log_info "Would apply EC2NodeClass from: $NODECLASS_FILE"
        log_info "Template variables:"
        log_info "  EKS_CLUSTER_NAME=$EKS_CLUSTER_NAME"
        log_info "  CLUSTER_VERSION=$CLUSTER_VERSION"
        log_info "  ALIAS=$ALIAS"
        exit 0
    fi

    # Apply NodePool
    log_step "Applying NodePool"
    if [[ -f "$NODEPOOL_FILE" ]]; then
        envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${ALIAS}' < "$NODEPOOL_FILE" | kubectl apply -f -
        log_success "NodePool applied"
    else
        log_warn "NodePool file not found: $NODEPOOL_FILE"
    fi

    # Apply EC2NodeClass
    log_step "Applying EC2NodeClass"
    if [[ -f "$NODECLASS_FILE" ]]; then
        envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${ALIAS}' < "$NODECLASS_FILE" | kubectl apply -f -
        log_success "EC2NodeClass applied"
    else
        log_warn "EC2NodeClass file not found: $NODECLASS_FILE"
    fi

    log_step "Complete"
    log_info "Karpenter resources configured"
    log_info "Check NodePools: kubectl get nodepools"
    log_info "Check NodeClasses: kubectl get ec2nodeclasses"
    exit 0
}

main "$@"
