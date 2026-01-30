#!/usr/bin/env bash
# IRSA (IAM Roles for Service Accounts) Scenario
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

Setup IAM Roles for Service Accounts (IRSA) on EKS.

OPTIONS:
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --namespace NS        Namespace (default: from kustomization.yaml)
    --service-account SA  Service account name (default: awscli-sa)
    --policy-arn ARN      IAM policy ARN to attach
    --policy-name NAME    IAM policy name (default: IAMReadOnlyAccess)
    --dry-run             Show what would be created
    --teardown            Remove resources
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Setup with defaults
    $(basename "$0")

    # Setup with custom policy
    $(basename "$0") --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

    # Dry run
    $(basename "$0") --dry-run

    # Teardown
    $(basename "$0") --teardown
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
NAMESPACE=""
SERVICE_ACCOUNT_NAME="awscli-sa"
POLICY_ARN=""
POLICY_NAME="IAMReadOnlyAccess"
DRY_RUN=false
TEARDOWN=false

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
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --service-account)
            SERVICE_ACCOUNT_NAME="$2"
            shift 2
            ;;
        --policy-arn)
            POLICY_ARN="$2"
            shift 2
            ;;
        --policy-name)
            POLICY_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --teardown)
            TEARDOWN=true
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
    
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    # Get namespace from kustomization.yaml if not specified
    if [[ -z "$NAMESPACE" ]] && [[ -f "${SCRIPT_DIR}/kustomization.yaml" ]]; then
        NAMESPACE=$(grep -E '^namespace:' "${SCRIPT_DIR}/kustomization.yaml" | awk '{print $2}' || echo "default")
    fi
    [[ -z "$NAMESPACE" ]] && NAMESPACE="default"
    
    # Get policy ARN if not specified
    if [[ -z "$POLICY_ARN" ]]; then
        POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)
    fi
}

# Teardown
teardown() {
    log_step "Teardown"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would delete service account"
        exit 0
    fi
    
    eksctl delete iamserviceaccount \
        --cluster "$CLUSTER_NAME" \
        --region "$REGION" \
        --namespace "$NAMESPACE" \
        --name "$SERVICE_ACCOUNT_NAME" 2>/dev/null || true
    
    log_success "Teardown complete"
    exit 0
}

# Main
main() {
    get_cluster_info
    
    if $TEARDOWN; then
        teardown
    fi
    
    log_step "Environment"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $REGION"
    log_info "Account: $AWS_ACCOUNT_ID"
    log_info "Namespace: $NAMESPACE"
    log_info "Service Account: $SERVICE_ACCOUNT_NAME"
    log_info "Policy: $POLICY_ARN"

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would create IAM service account: $SERVICE_ACCOUNT_NAME"
        log_info "Would attach policy: $POLICY_ARN"
        exit 0
    fi

    # Create IAM service account
    log_step "Creating IAM Service Account"
    
    eksctl create iamserviceaccount \
        --namespace "$NAMESPACE" \
        --region "$REGION" \
        --cluster "$CLUSTER_NAME" \
        --name "$SERVICE_ACCOUNT_NAME" \
        --attach-policy-arn "$POLICY_ARN" \
        --approve \
        --override-existing-serviceaccounts

    log_success "IAM service account created"

    log_step "Complete"
    log_info "IRSA configured for $SERVICE_ACCOUNT_NAME in $NAMESPACE"
    log_info "Test: kubectl run test-pod -n $NAMESPACE --image=amazon/aws-cli --overrides='{\"spec\":{\"serviceAccountName\":\"$SERVICE_ACCOUNT_NAME\"}}' -- iam get-user"
    exit 0
}

main "$@"
