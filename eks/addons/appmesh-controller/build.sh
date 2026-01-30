#!/usr/bin/env bash
# AWS App Mesh Controller installation for EKS
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

Install AWS App Mesh Controller on an EKS cluster.

OPTIONS:
    --chart-version VER   Helm chart version (default: latest)
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --namespace NS        Namespace (default: appmesh-system)
    --list-versions       List available chart versions and exit
    --dry-run             Show what would be installed
    --skip-iam            Skip IAM policy/service account creation
    --uninstall           Uninstall the controller
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # List available versions
    $(basename "$0") --list-versions

    # Install latest version
    $(basename "$0")

    # Install specific version
    $(basename "$0") --chart-version 1.12.0

    # Dry run
    $(basename "$0") --dry-run
EOF
}

show_version() {
    echo "$(basename "$0") version ${SCRIPT_VERSION}"
}

# Logging - separate stdout/stderr
log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&1; }
log_success() { echo -e "${GREEN}[OK]${NC} $*" >&1; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "\n${YELLOW}=== $* ===${NC}" >&1; }

# Configuration
NAMESPACE="appmesh-system"
SERVICE_ACCOUNT_NAME="appmesh-controller"
IAM_POLICY_NAME="AppMesh_Controller_Policy"
REPO_NAME="eks"
REPO_URL="https://aws.github.io/eks-charts"
CHART_NAME="appmesh-controller"

# Defaults
CHART_VERSION=""
APP_VERSION=""
CLUSTER_NAME=""
REGION=""
LIST_VERSIONS=false
DRY_RUN=false
SKIP_IAM=false
UNINSTALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --chart-version)
            CHART_VERSION="$2"
            shift 2
            ;;
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
        --list-versions)
            LIST_VERSIONS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-iam)
            SKIP_IAM=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
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

# Get cluster info from context if not provided
get_cluster_info() {
    if [[ -z "$CLUSTER_NAME" ]] || [[ -z "$REGION" ]]; then
        local context
        context=$(kubectl config current-context)
        
        if [[ -z "$CLUSTER_NAME" ]]; then
            CLUSTER_NAME=$(echo "$context" | awk -F: '{split($NF,a,"/"); print a[2]}')
        fi
        
        if [[ -z "$REGION" ]]; then
            REGION=$(echo "$context" | awk -F: '{print $4}')
        fi
    fi
    
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
}

# Add/update Helm repo
setup_repo() {
    log_step "Helm Repository"
    helm repo add "$REPO_NAME" "$REPO_URL" > /dev/null 2>&1 || true
    helm repo update "$REPO_NAME" > /dev/null 2>&1
    log_success "Repository ready: $REPO_NAME"
}

# List available versions
list_versions() {
    setup_repo
    log_step "Available Chart Versions"
    echo -e "${GREEN}CHART VERSION   APP VERSION${NC}"
    helm search repo "${REPO_NAME}/${CHART_NAME}" --versions --output json | \
        jq -r '.[] | "\(.version)\t\(.app_version)"' | head -n 15
}

# Get latest versions
get_latest_versions() {
    local versions
    versions=$(helm search repo "${REPO_NAME}/${CHART_NAME}" --versions --output json)
    CHART_VERSION=$(echo "$versions" | jq -r '.[0].version')
    APP_VERSION=$(echo "$versions" | jq -r '.[0].app_version')
}

# Uninstall
uninstall() {
    log_step "Uninstalling App Mesh Controller"
    
    if helm list -n "$NAMESPACE" | grep -q "$CHART_NAME"; then
        if $DRY_RUN; then
            log_info "[DRY RUN] Would uninstall $CHART_NAME from $NAMESPACE"
        else
            helm uninstall "$CHART_NAME" -n "$NAMESPACE"
            log_success "Uninstalled App Mesh Controller"
        fi
    else
        log_warn "$CHART_NAME not found in $NAMESPACE"
    fi
    exit 0
}

# Main installation
main() {
    # Handle uninstall
    if $UNINSTALL; then
        setup_repo
        uninstall
    fi

    # List versions mode
    if $LIST_VERSIONS; then
        list_versions
        exit 0
    fi

    # Get cluster info
    get_cluster_info
    
    log_step "Environment"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $REGION"
    log_info "Account: $AWS_ACCOUNT_ID"

    # Setup repo
    setup_repo

    # Get versions
    if [[ -z "$CHART_VERSION" ]]; then
        get_latest_versions
        log_info "Using latest: chart=$CHART_VERSION app=$APP_VERSION"
    else
        [[ -z "$APP_VERSION" ]] && APP_VERSION="$CHART_VERSION"
        log_info "Using specified: chart=$CHART_VERSION"
    fi

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would install App Mesh Controller"
        log_info "  Chart Version: $CHART_VERSION"
        log_info "  Namespace: $NAMESPACE"
        log_info "  Cluster: $CLUSTER_NAME"
        exit 0
    fi

    # Create namespace
    log_step "Namespace"
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    log_success "Namespace ready: $NAMESPACE"

    # IAM setup
    if ! $SKIP_IAM; then
        log_step "IAM Policy"
        local policy_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${IAM_POLICY_NAME}"
        
        if aws iam get-policy --policy-arn "$policy_arn" > /dev/null 2>&1; then
            log_success "IAM policy exists"
        else
            if [[ -f "${SCRIPT_DIR}/policy.json" ]]; then
                aws iam create-policy \
                    --policy-name "$IAM_POLICY_NAME" \
                    --policy-document "file://${SCRIPT_DIR}/policy.json" > /dev/null
                log_success "IAM policy created"
            else
                log_warn "policy.json not found, skipping IAM policy creation"
            fi
        fi

        log_step "Service Account"
        eksctl create iamserviceaccount \
            --namespace "$NAMESPACE" \
            --region "$REGION" \
            --cluster "$CLUSTER_NAME" \
            --name "$SERVICE_ACCOUNT_NAME" \
            --attach-policy-arn "$policy_arn" \
            --approve \
            --override-existing-serviceaccounts
        log_success "Service account configured"
    fi

    # Apply CRDs
    log_step "CRDs"
    kubectl apply -k "github.com/aws/eks-charts//stable/appmesh-controller/crds?ref=master"
    log_success "CRDs applied"

    # Install/Upgrade
    log_step "Installing App Mesh Controller"
    
    helm upgrade --install "$CHART_NAME" \
        "${REPO_NAME}/${CHART_NAME}" \
        --namespace "$NAMESPACE" \
        --version "$CHART_VERSION" \
        --set serviceAccount.create=false \
        --set serviceAccount.name="$SERVICE_ACCOUNT_NAME" \
        --set region="$REGION"

    log_success "App Mesh Controller installed"
    
    log_step "Verification"
    helm list -n "$NAMESPACE" --filter "$CHART_NAME"
    
    log_info "Installation complete!"
    log_info "Check pods: kubectl get pods -n $NAMESPACE"
    exit 0
}

main "$@"
