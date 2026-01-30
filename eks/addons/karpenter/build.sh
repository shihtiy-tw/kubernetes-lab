#!/usr/bin/env bash
# Karpenter installation for EKS
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

Install Karpenter on an EKS cluster.

OPTIONS:
    --chart-version VER   Helm chart version (default: latest)
    --app-version VER     Application version (default: matches chart)
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --namespace NS        Namespace (default: kube-system)
    --list-versions       Show latest version info
    --dry-run             Show what would be installed
    --skip-cfn            Skip CloudFormation stack deployment
    --skip-iam            Skip IAM resources setup
    --uninstall           Uninstall Karpenter
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Install latest version
    $(basename "$0")

    # Install specific version
    $(basename "$0") --chart-version 1.0.7 --app-version 1.0.7

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

# Configuration
NAMESPACE="kube-system"
SERVICE_ACCOUNT_NAME="karpenter"

# Defaults
CHART_VERSION=""
APP_VERSION=""
CLUSTER_NAME=""
REGION=""
LIST_VERSIONS=false
DRY_RUN=false
SKIP_CFN=false
SKIP_IAM=false
UNINSTALL=false

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
        --skip-cfn)
            SKIP_CFN=true
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
    CLUSTER_ENDPOINT=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query 'cluster.endpoint' --output text)
    
    # Derived names
    IAM_ROLE_NAME="${CLUSTER_NAME}-karpenter"
    IAM_POLICY_NAME="KarpenterControllerPolicy-${CLUSTER_NAME}"
}

# Get latest version from OCI registry
get_latest_versions() {
    log_info "Fetching latest version from OCI registry..."
    local chart_info
    chart_info=$(helm show chart oci://public.ecr.aws/karpenter/karpenter 2>/dev/null)
    CHART_VERSION=$(echo "$chart_info" | grep '^version:' | awk '{print $2}')
    APP_VERSION=$(echo "$chart_info" | grep '^appVersion:' | awk '{print $2}')
}

# List versions
list_versions() {
    get_latest_versions
    log_step "Latest Karpenter Versions"
    echo -e "${GREEN}Chart Version: ${CHART_VERSION}${NC}"
    echo -e "${GREEN}App Version:   ${APP_VERSION}${NC}"
    log_info "For all versions, visit: https://gallery.ecr.aws/karpenter/karpenter"
}

# Uninstall
uninstall() {
    log_step "Uninstalling Karpenter"
    
    if helm list -n "$NAMESPACE" | grep -q "karpenter"; then
        if $DRY_RUN; then
            log_info "[DRY RUN] Would uninstall karpenter from $NAMESPACE"
        else
            helm uninstall karpenter -n "$NAMESPACE" || true
            helm uninstall karpenter-crd -n "$NAMESPACE" || true
            log_success "Uninstalled Karpenter"
        fi
    else
        log_warn "Karpenter not found in $NAMESPACE"
    fi
    exit 0
}

# Main installation
main() {
    # Handle uninstall
    if $UNINSTALL; then
        get_cluster_info
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
    log_info "Endpoint: $CLUSTER_ENDPOINT"

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
        log_info "Would install Karpenter"
        log_info "  Chart Version: $CHART_VERSION"
        log_info "  App Version: $APP_VERSION"
        log_info "  Cluster: $CLUSTER_NAME"
        log_info "  Namespace: $NAMESPACE"
        [[ "$SKIP_CFN" != true ]] && log_info "Would deploy CloudFormation stack"
        [[ "$SKIP_IAM" != true ]] && log_info "Would create IAM resources"
        exit 0
    fi

    # CloudFormation setup
    if ! $SKIP_CFN; then
        log_step "CloudFormation Stack"
        local cfn_url="https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${APP_VERSION}/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml"
        
        local temp_cfn
        temp_cfn=$(mktemp)
        
        if curl -fsSL "$cfn_url" -o "$temp_cfn"; then
            log_info "Deploying CloudFormation stack..."
            aws cloudformation deploy \
                --stack-name "Karpenter-${CLUSTER_NAME}" \
                --template-file "$temp_cfn" \
                --capabilities CAPABILITY_NAMED_IAM \
                --parameter-overrides "ClusterName=${CLUSTER_NAME}" \
                --no-fail-on-empty-changeset
            rm -f "$temp_cfn"
            log_success "CloudFormation stack deployed"
        else
            log_warn "Could not download CloudFormation template"
            rm -f "$temp_cfn"
        fi
    fi

    # IAM setup
    if ! $SKIP_IAM; then
        log_step "IAM Identity Mapping"
        eksctl create iamidentitymapping \
            --username "system:node:{{EC2PrivateDNSName}}" \
            --region "$REGION" \
            --cluster "$CLUSTER_NAME" \
            --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
            --group "system:bootstrappers" \
            --group "system:nodes" || true
        log_success "IAM identity mapping configured"

        log_step "Service Account"
        eksctl create iamserviceaccount \
            --namespace "$NAMESPACE" \
            --region "$REGION" \
            --cluster "$CLUSTER_NAME" \
            --name "$SERVICE_ACCOUNT_NAME" \
            --role-name "$IAM_ROLE_NAME" \
            --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${IAM_POLICY_NAME}" \
            --approve \
            --override-existing-serviceaccounts
        log_success "Service account configured"
    fi

    # Install CRDs
    log_step "Installing Karpenter CRDs"
    helm registry logout public.ecr.aws > /dev/null 2>&1 || true
    helm upgrade --install karpenter-crd \
        oci://public.ecr.aws/karpenter/karpenter-crd \
        --version "$CHART_VERSION" \
        --namespace "$NAMESPACE" \
        --create-namespace
    log_success "CRDs installed"

    # Install Karpenter
    log_step "Installing Karpenter"
    helm upgrade --install karpenter \
        oci://public.ecr.aws/karpenter/karpenter \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --version "$CHART_VERSION" \
        --set serviceAccount.create=false \
        --set serviceAccount.name="$SERVICE_ACCOUNT_NAME" \
        --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${IAM_ROLE_NAME}" \
        --set settings.clusterName="$CLUSTER_NAME" \
        --set settings.interruptionQueue="$CLUSTER_NAME" \
        --set settings.clusterEndpoint="$CLUSTER_ENDPOINT" \
        --set controller.resources.requests.cpu=500m \
        --set controller.resources.requests.memory=500Mi \
        --set controller.resources.limits.cpu=1 \
        --set controller.resources.limits.memory=1Gi \
        --wait

    log_success "Karpenter installed"
    
    log_step "Verification"
    helm list -n "$NAMESPACE" --filter karpenter
    
    log_info "Installation complete!"
    log_info "Next: Create NodePool and EC2NodeClass resources"
    exit 0
}

main "$@"
