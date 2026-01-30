#!/usr/bin/env bash
# Create an EKS cluster using eksctl
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create an EKS cluster using eksctl with template configuration.

OPTIONS:
    --version K8S_VER     Kubernetes version (e.g., 1.29)
    --region REGION       AWS region (default: us-east-1)
    --config TYPE         Cluster config type: minimal, standard, full (default: standard)
    --name NAME           Cluster name (default: from .env file)
    --dry-run             Validate template without creating
    --output-file PATH    Write generated YAML to file
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Create cluster with defaults
    $(basename "$0") --version 1.29

    # Create in specific region
    $(basename "$0") --version 1.29 --region us-west-2

    # Dry run to validate
    $(basename "$0") --version 1.29 --dry-run

    # Use full configuration
    $(basename "$0") --version 1.29 --config full
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
K8S_VERSION=""
REGION="us-east-1"
CONFIG_TYPE="standard"
CLUSTER_NAME=""
DRY_RUN=false
OUTPUT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            K8S_VERSION="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --config)
            CONFIG_TYPE="$2"
            shift 2
            ;;
        --name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --output-file)
            OUTPUT_FILE="$2"
            shift 2
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

# Validate required args
if [[ -z "$K8S_VERSION" ]]; then
    log_error "Kubernetes version required. Use --version"
    exit 1
fi

# Load environment config
load_config() {
    local config_file="$PROJECT_DIR/clusters/config/.env"
    
    if [[ -f "$config_file" ]]; then
        # shellcheck source=/dev/null
        source "$config_file"
    fi
    
    # Use provided name or fall back to env
    CLUSTER_NAME="${CLUSTER_NAME:-${EKS_CLUSTER_NAME:-eks-lab-cluster}}"
    
    # Set derived values
    export EKS_CLUSTER_NAME="$CLUSTER_NAME"
    export EKS_CLUSTER_REGION="$REGION"
    export CLUSTER_VERSION="$K8S_VERSION"
    
    # Get availability zones
    AZ_ARRAY=$(aws ec2 describe-availability-zones \
        --region "$REGION" \
        --query 'AvailabilityZones[0:3].ZoneName' \
        --output text | tr '\t' ',')
    export AZ_ARRAY
    
    # Get current IAM user
    IAM_USER=$(aws sts get-caller-identity --query Arn --output text)
    export IAM_USER
    
    # Secret key ARN (optional)
    export SECRET_KEY_ARN="${SECRET_KEY_ARN:-}"
}

main() {
    log_step "Configuration"
    
    load_config
    
    log_info "Cluster Name: $CLUSTER_NAME"
    log_info "K8s Version: $K8S_VERSION"
    log_info "Region: $REGION"
    log_info "Config Type: $CONFIG_TYPE"
    log_info "AZs: $AZ_ARRAY"
    log_info "IAM User: $IAM_USER"
    
    # Find template
    local template_file="$PROJECT_DIR/clusters/eksctl-cluster-${CONFIG_TYPE}.yaml"
    
    if [[ ! -f "$template_file" ]]; then
        log_error "Template not found: $template_file"
        log_info "Available configs: minimal, standard, full"
        exit 1
    fi
    
    # Generate output path
    local version_dir="$PROJECT_DIR/clusters/versions/$(echo "$K8S_VERSION" | tr '.' '-')"
    mkdir -p "$version_dir"
    
    local output="${OUTPUT_FILE:-${version_dir}/${CLUSTER_NAME}-${REGION}.yaml}"
    
    log_step "Generating Cluster Config"
    log_info "Template: $template_file"
    log_info "Output: $output"
    
    # Generate config using envsubst
    envsubst '${EKS_CLUSTER_NAME},${EKS_CLUSTER_REGION},${CLUSTER_VERSION},${AZ_ARRAY},${IAM_USER},${SECRET_KEY_ARN}' \
        < "$template_file" > "$output"
    
    log_success "Config generated: $output"
    
    log_step "Validating Template"
    if eksctl create cluster -f "$output" --dry-run > /dev/null 2>&1; then
        log_success "Template validation passed"
    else
        log_error "Template validation failed"
        eksctl create cluster -f "$output" --dry-run
        exit 1
    fi
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would create cluster with:"
        cat "$output"
        exit 0
    fi
    
    log_step "Creating Cluster"
    log_warn "This will take 15-25 minutes..."
    
    if eksctl create cluster -f "$output"; then
        log_success "Cluster created successfully!"
        log_info "Get nodes: kubectl get nodes"
        exit 0
    else
        log_error "Cluster creation failed"
        exit 2
    fi
}

main "$@"
