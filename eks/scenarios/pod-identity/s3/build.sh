#!/usr/bin/env bash
# Pod Identity S3 Access Scenario
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

Setup EKS Pod Identity for S3 access.

OPTIONS:
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --namespace NS        Namespace (default: pod-identity)
    --service-account SA  Service account name (default: s3-reader)
    --role-name NAME      IAM role name (default: s3_reader)
    --dry-run             Show what would be created
    --deploy              Deploy the test pod
    --teardown            Remove resources
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Setup with defaults
    $(basename "$0")

    # Setup with custom names
    $(basename "$0") --namespace my-app --service-account my-sa

    # Dry run
    $(basename "$0") --dry-run

    # Setup and deploy test pod
    $(basename "$0") --deploy

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
NAMESPACE="pod-identity"
SERVICE_ACCOUNT_NAME="s3-reader"
POLICY_NAME="s3_policy"
ROLE_NAME="s3_reader"
DRY_RUN=false
DEPLOY=false
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
        --role-name)
            ROLE_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --deploy)
            DEPLOY=true
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
}

# Teardown
teardown() {
    log_step "Teardown"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would delete pod identity association"
        log_info "[DRY RUN] Would delete IAM role and policy"
        exit 0
    fi
    
    aws eks delete-pod-identity-association \
        --cluster-name "$CLUSTER_NAME" \
        --association-id "$(aws eks list-pod-identity-associations --cluster-name "$CLUSTER_NAME" --namespace "$NAMESPACE" --service-account "$SERVICE_ACCOUNT_NAME" --query 'associations[0].associationId' --output text)" 2>/dev/null || true
    
    aws iam detach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" 2>/dev/null || true
    
    aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null || true
    aws iam delete-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" 2>/dev/null || true
    
    kubectl delete namespace "$NAMESPACE" 2>/dev/null || true
    
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
    log_info "Role Name: $ROLE_NAME"

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would create IAM policy: $POLICY_NAME"
        log_info "Would create IAM role: $ROLE_NAME"
        log_info "Would create namespace: $NAMESPACE"
        log_info "Would create service account: $SERVICE_ACCOUNT_NAME"
        log_info "Would create pod identity association"
        exit 0
    fi

    # Create IAM policy
    log_step "IAM Policy"
    local policy_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
    
    if aws iam get-policy --policy-arn "$policy_arn" > /dev/null 2>&1; then
        log_success "Policy exists"
    else
        if [[ -f "${SCRIPT_DIR}/s3-policy.json" ]]; then
            aws iam create-policy \
                --policy-name "$POLICY_NAME" \
                --policy-document "file://${SCRIPT_DIR}/s3-policy.json" > /dev/null
            log_success "Policy created"
        else
            log_error "s3-policy.json not found"
            exit 1
        fi
    fi

    # Create namespace and service account
    log_step "Kubernetes Resources"
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    if [[ -f "${SCRIPT_DIR}/k8s-serviceaccount.yaml" ]]; then
        kubectl apply -f "${SCRIPT_DIR}/k8s-serviceaccount.yaml"
    else
        kubectl create serviceaccount "$SERVICE_ACCOUNT_NAME" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    fi
    log_success "Namespace and service account ready"

    # Create IAM role
    log_step "IAM Role"
    if ! aws iam get-role --role-name "$ROLE_NAME" > /dev/null 2>&1; then
        if [[ -f "${SCRIPT_DIR}/trust-relationship.json" ]]; then
            aws iam create-role \
                --role-name "$ROLE_NAME" \
                --assume-role-policy-document "file://${SCRIPT_DIR}/trust-relationship.json" \
                --description "Pod identity role for $SERVICE_ACCOUNT_NAME" > /dev/null
        fi
    fi
    
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "$policy_arn" 2>/dev/null || true
    log_success "Role configured"

    # Create pod identity association
    log_step "Pod Identity Association"
    aws eks create-pod-identity-association \
        --cluster-name "$CLUSTER_NAME" \
        --role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}" \
        --namespace "$NAMESPACE" \
        --service-account "$SERVICE_ACCOUNT_NAME" 2>/dev/null || log_warn "Association may already exist"
    log_success "Pod identity configured"

    # Deploy test pod
    if $DEPLOY; then
        log_step "Deploying Test Pod"
        if [[ -f "${SCRIPT_DIR}/k8s-deployment.yaml" ]]; then
            kubectl apply -f "${SCRIPT_DIR}/k8s-deployment.yaml"
            log_success "Test pod deployed"
        else
            log_warn "k8s-deployment.yaml not found"
        fi
    fi

    log_step "Complete"
    log_info "Pod identity configured for $SERVICE_ACCOUNT_NAME in $NAMESPACE"
    log_info "Test: kubectl run test-pod -n $NAMESPACE --image=amazon/aws-cli --overrides='{\"spec\":{\"serviceAccountName\":\"$SERVICE_ACCOUNT_NAME\"}}' -- s3 ls"
    exit 0
}

main "$@"
