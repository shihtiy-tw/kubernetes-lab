#!/usr/bin/env bash
# Fargate Nginx Logging to OpenSearch Scenario
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

Setup Fargate logging to OpenSearch.

OPTIONS:
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --skip-terraform      Skip Terraform apply
    --dry-run             Show what would be configured
    --teardown            Remove the configuration
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Setup logging
    $(basename "$0")

    # Skip Terraform (use existing OpenSearch)
    $(basename "$0") --skip-terraform

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
POLICY_NAME="eks-fargate-logging-policy-opensearch"
POLICY_URL="https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/amazon-elasticsearch/permissions.json"

# Defaults
CLUSTER_NAME=""
REGION=""
SKIP_TERRAFORM=false
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
        --skip-terraform)
            SKIP_TERRAFORM=true
            shift
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

    # Get Fargate role
    local role_name
    role_name=$(eksctl get fargateprofile --cluster "$CLUSTER_NAME" --region "$REGION" --output json 2>/dev/null | jq -r '.[0].podExecutionRoleARN // empty | split("/") | last' || echo "")

    if [[ -z "$role_name" ]]; then
        log_warn "No Fargate profile found, some steps may fail"
    else
        log_info "Fargate Role: $role_name"
    fi

    if $TEARDOWN; then
        log_step "Teardown"
        if $DRY_RUN; then
            log_info "[DRY RUN] Would detach policy and destroy Terraform"
            exit 0
        fi
        
        if [[ -n "$role_name" ]]; then
            aws iam detach-role-policy \
                --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" \
                --role-name "$role_name" 2>/dev/null || true
        fi
        
        if [[ -d "terraform" ]]; then
            export TF_VAR_EKSCLUSTER="$CLUSTER_NAME"
            terraform -chdir="$SCRIPT_DIR" destroy -auto-approve 2>/dev/null || true
        fi
        log_success "Teardown complete"
        exit 0
    fi

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would create IAM policy: $POLICY_NAME"
        log_info "Would attach policy to role: $role_name"
        ! $SKIP_TERRAFORM && log_info "Would run terraform apply"
        exit 0
    fi

    # Create policy
    log_step "Creating IAM Policy"
    local temp_file
    temp_file=$(mktemp)
    curl -sL "$POLICY_URL" -o "$temp_file"
    
    local policy_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
    if ! aws iam get-policy --policy-arn "$policy_arn" > /dev/null 2>&1; then
        aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "file://${temp_file}" > /dev/null
        log_success "Policy created"
    else
        log_info "Policy already exists"
    fi
    rm -f "$temp_file"

    # Attach policy
    if [[ -n "$role_name" ]]; then
        log_step "Attaching Policy"
        aws iam attach-role-policy \
            --policy-arn "$policy_arn" \
            --role-name "$role_name"
        log_success "Policy attached to $role_name"
    fi

    # Terraform
    if ! $SKIP_TERRAFORM && [[ -d "terraform" ]]; then
        log_step "Running Terraform"
        export TF_VAR_EKSCLUSTER="$CLUSTER_NAME"
        terraform -chdir="$SCRIPT_DIR" apply -auto-approve
        log_success "Terraform applied"
    fi

    log_step "Complete"
    log_info "Fargate logging to OpenSearch configured"
    log_info "Next: Configure OpenSearch access and apply ConfigMap"
    exit 0
}

main "$@"
