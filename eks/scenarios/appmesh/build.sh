#!/usr/bin/env bash
# App Mesh Sample Scenario
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

Deploy App Mesh sample application with service mesh configuration.

OPTIONS:
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --namespace NS        Namespace for the sample app (default: my-apps)
    --dry-run             Show what would be deployed
    --teardown            Remove the sample application
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Deploy sample app
    $(basename "$0")

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

# Configuration
POLICY_NAME="AppMesh-sample-policy"

# Defaults
CLUSTER_NAME=""
REGION=""
NAMESPACE="my-apps"
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
}

# Main
main() {
    get_cluster_info
    cd "$SCRIPT_DIR"

    log_step "Environment"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $REGION"
    log_info "Account: $AWS_ACCOUNT_ID"
    log_info "Namespace: $NAMESPACE"

    if $TEARDOWN; then
        log_step "Teardown"
        if $DRY_RUN; then
            log_info "[DRY RUN] Would delete Kubernetes resources"
            log_info "[DRY RUN] Would delete IAM service account"
            exit 0
        fi
        
        kubectl delete -f mesh.yaml -f service-a.yaml -f service-b.yaml 2>/dev/null || true
        kubectl delete namespace "$NAMESPACE" 2>/dev/null || true
        eksctl delete iamserviceaccount \
            --cluster "$CLUSTER_NAME" \
            --namespace "$NAMESPACE" \
            --name my-service 2>/dev/null || true
        log_success "Teardown complete"
        exit 0
    fi

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would create IAM policy: $POLICY_NAME"
        log_info "Would create namespace: $NAMESPACE"
        log_info "Would create IAM service account: my-service"
        log_info "Would apply mesh, service-a, service-b"
        exit 0
    fi

    # Create IAM policy
    log_step "Creating IAM Policy"
    
    if [[ -f "${SCRIPT_DIR}/proxy-auth-template.json" ]]; then
        sed -e "s/{{ REGION }}/$REGION/g" -e "s/{{ AWS_ACCOUNT_ID }}/$AWS_ACCOUNT_ID/g" \
            "${SCRIPT_DIR}/proxy-auth-template.json" > "${SCRIPT_DIR}/proxy-auth.json"
        
        local policy_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
        if ! aws iam get-policy --policy-arn "$policy_arn" > /dev/null 2>&1; then
            aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "file://${SCRIPT_DIR}/proxy-auth.json" > /dev/null
            log_success "Policy created"
        else
            log_info "Policy already exists"
        fi
        rm -f "${SCRIPT_DIR}/proxy-auth.json"
    else
        log_warn "proxy-auth-template.json not found, skipping policy creation"
    fi

    # Create namespace
    log_step "Creating Namespace"
    if [[ -f "${SCRIPT_DIR}/namespace.yaml" ]]; then
        kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"
    else
        kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    fi
    log_success "Namespace ready"

    # Create service account
    log_step "Creating IAM Service Account"
    eksctl create iamserviceaccount \
        --cluster "$CLUSTER_NAME" \
        --namespace "$NAMESPACE" \
        --name my-service \
        --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" \
        --override-existing-serviceaccounts \
        --approve
    log_success "Service account created"

    # Apply resources
    log_step "Deploying App Mesh Resources"
    kubectl apply -f "${SCRIPT_DIR}/mesh.yaml" -f "${SCRIPT_DIR}/service-a.yaml" -f "${SCRIPT_DIR}/service-b.yaml"
    log_success "Resources deployed"

    log_step "Complete"
    log_info "App Mesh sample deployed"
    log_info "Check mesh: kubectl get mesh,virtualservice,virtualnode -n $NAMESPACE"
    exit 0
}

main "$@"
