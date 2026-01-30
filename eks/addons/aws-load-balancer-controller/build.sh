#!/usr/bin/env bash
# AWS Load Balancer Controller installation for EKS
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

Install AWS Load Balancer Controller on an EKS cluster.

OPTIONS:
    --chart-version VER   Helm chart version (default: latest)
    --app-version VER     Application version (default: matches chart)
    --cluster NAME        EKS cluster name (default: from current context)
    --region REGION       AWS region (default: from current context)
    --list-versions       List available chart versions and exit
    --dry-run             Show what would be installed
    --skip-iam            Skip IAM policy/service account creation
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # List available versions
    $(basename "$0") --list-versions

    # Install latest version
    $(basename "$0")

    # Install specific version
    $(basename "$0") --chart-version 1.8.3 --app-version v2.8.3

    # Dry run
    $(basename "$0") --dry-run

    # Install on specific cluster
    $(basename "$0") --cluster my-cluster --region us-east-1
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

# Defaults
CHART_VERSION=""
APP_VERSION=""
CLUSTER_NAME=""
REGION=""
LIST_VERSIONS=false
DRY_RUN=false
SKIP_IAM=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --chart-version)
            CHART_VERSION="$2"
            shift 2
            ;;
        --app-version)
            APP_VERSION="$2"
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

# Configuration
IAM_POLICY_NAME="AWS_Load_Balancer_Controller_Policy"
SERVICE_ACCOUNT_NAME="aws-load-balancer-controller"

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
    VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query 'cluster.resourcesVpcConfig.vpcId' --output text --region "$REGION")
}

# List available versions
list_versions() {
    log_step "Available Chart Versions"
    
    helm repo add eks https://aws.github.io/eks-charts > /dev/null 2>&1 || true
    helm repo update eks > /dev/null 2>&1
    
    echo -e "${GREEN}CHART VERSION   APP VERSION${NC}"
    helm search repo eks/aws-load-balancer-controller --versions --output json | \
        jq -r '.[] | "\(.version)\t\(.app_version)"' | head -n 15
}

# Get latest versions
get_latest_versions() {
    local versions
    versions=$(helm search repo eks/aws-load-balancer-controller --versions --output json)
    CHART_VERSION=$(echo "$versions" | jq -r '.[0].version')
    APP_VERSION=$(echo "$versions" | jq -r '.[0].app_version')
}

# Main installation
main() {
    # List versions mode
    if $LIST_VERSIONS; then
        helm repo add eks https://aws.github.io/eks-charts > /dev/null 2>&1 || true
        helm repo update eks > /dev/null 2>&1
        list_versions
        exit 0
    fi

    # Get cluster info
    get_cluster_info
    
    log_step "Environment"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $REGION"
    log_info "Account: $AWS_ACCOUNT_ID"
    log_info "VPC: $VPC_ID"

    # Add Helm repo
    log_step "Helm Repository"
    helm repo add eks https://aws.github.io/eks-charts > /dev/null 2>&1 || true
    helm repo update eks > /dev/null 2>&1
    log_success "EKS Charts repo ready"

    # Get versions
    if [[ -z "$CHART_VERSION" ]]; then
        get_latest_versions
        log_info "Using latest: chart=$CHART_VERSION app=$APP_VERSION"
    else
        [[ -z "$APP_VERSION" ]] && APP_VERSION="$CHART_VERSION"
        log_info "Using specified: chart=$CHART_VERSION app=$APP_VERSION"
    fi

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would install AWS Load Balancer Controller"
        log_info "  Chart Version: $CHART_VERSION"
        log_info "  App Version: $APP_VERSION"
        log_info "  Cluster: $CLUSTER_NAME"
        log_info "  Region: $REGION"
        exit 0
    fi

    # IAM setup
    if ! $SKIP_IAM; then
        log_step "IAM Policy"
        local policy_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${IAM_POLICY_NAME}"
        
        if aws iam get-policy --policy-arn "$policy_arn" > /dev/null 2>&1; then
            log_success "IAM policy exists"
            # Update policy
            aws iam create-policy-version \
                --policy-arn "$policy_arn" \
                --policy-document "file://${SCRIPT_DIR}/policy.json" \
                --set-as-default > /dev/null 2>&1 || log_warn "Could not update policy (may have max versions)"
        else
            aws iam create-policy \
                --policy-name "$IAM_POLICY_NAME" \
                --policy-document "file://${SCRIPT_DIR}/policy.json" > /dev/null
            log_success "IAM policy created"
        fi

        log_step "Service Account"
        eksctl create iamserviceaccount \
            --namespace kube-system \
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
    kubectl apply -k "github.com/aws/eks-charts//stable/aws-load-balancer-controller/crds?ref=master"
    log_success "CRDs applied"

    # Install/Upgrade controller
    log_step "Installing Controller"
    helm upgrade --install aws-load-balancer-controller \
        eks/aws-load-balancer-controller \
        --namespace kube-system \
        --version "$CHART_VERSION" \
        --set serviceAccount.create=false \
        --set serviceAccount.name="$SERVICE_ACCOUNT_NAME" \
        --set image.repository=public.ecr.aws/eks/aws-load-balancer-controller \
        --set image.tag="$APP_VERSION" \
        --set clusterName="$CLUSTER_NAME" \
        --set region="$REGION" \
        --set vpcId="$VPC_ID"

    log_success "AWS Load Balancer Controller installed"
    
    log_step "Verification"
    helm list -n kube-system -f aws-load-balancer-controller
    
    log_info "Installation complete!"
    exit 0
}

main "$@"
