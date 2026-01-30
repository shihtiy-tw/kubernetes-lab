#!/usr/bin/env bash
# EKS Access Entry Configuration
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

Configure EKS access entries for cluster access management.

OPTIONS:
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --principal-arn ARN   IAM principal ARN (user/role)
    --access-policy POL   Access policy (AmazonEKSClusterAdminPolicy, etc.)
    --type TYPE           Principal type: STANDARD, EC2_LINUX, EC2_WINDOWS
    --list                List existing access entries
    --dry-run             Show what would be configured
    --delete              Delete the access entry
    -h, --help            Show this help message
    -v, --version         Show script version

ACCESS POLICIES:
    - AmazonEKSClusterAdminPolicy
    - AmazonEKSAdminPolicy
    - AmazonEKSEditPolicy
    - AmazonEKSViewPolicy

EXAMPLES:
    # List access entries
    $(basename "$0") --list

    # Add cluster admin access
    $(basename "$0") --principal-arn arn:aws:iam::123456789:user/admin --access-policy AmazonEKSClusterAdminPolicy

    # Dry run
    $(basename "$0") --principal-arn arn:aws:iam::123456789:role/DevRole --dry-run

    # Delete access entry
    $(basename "$0") --principal-arn arn:aws:iam::123456789:user/admin --delete
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
PRINCIPAL_ARN=""
ACCESS_POLICY="AmazonEKSClusterAdminPolicy"
PRINCIPAL_TYPE="STANDARD"
LIST_ENTRIES=false
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
        --principal-arn)
            PRINCIPAL_ARN="$2"
            shift 2
            ;;
        --access-policy)
            ACCESS_POLICY="$2"
            shift 2
            ;;
        --type)
            PRINCIPAL_TYPE="$2"
            shift 2
            ;;
        --list)
            LIST_ENTRIES=true
            shift
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
}

# List access entries
list_entries() {
    log_step "Access Entries for $CLUSTER_NAME"
    
    aws eks list-access-entries \
        --cluster-name "$CLUSTER_NAME" \
        --region "$REGION" \
        --output table
    
    exit 0
}

# Delete access entry
delete_entry() {
    log_step "Deleting Access Entry"
    
    if [[ -z "$PRINCIPAL_ARN" ]]; then
        log_error "--principal-arn is required for delete"
        exit 1
    fi
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would delete access entry for: $PRINCIPAL_ARN"
        exit 0
    fi
    
    aws eks delete-access-entry \
        --cluster-name "$CLUSTER_NAME" \
        --region "$REGION" \
        --principal-arn "$PRINCIPAL_ARN"
    
    log_success "Access entry deleted"
    exit 0
}

# Main
main() {
    get_cluster_info
    
    log_step "Environment"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $REGION"
    
    if $LIST_ENTRIES; then
        list_entries
    fi
    
    if $DELETE; then
        delete_entry
    fi
    
    if [[ -z "$PRINCIPAL_ARN" ]]; then
        log_error "--principal-arn is required"
        echo "Run '$(basename "$0") --help' for usage." >&2
        exit 1
    fi
    
    log_info "Principal: $PRINCIPAL_ARN"
    log_info "Policy: $ACCESS_POLICY"
    log_info "Type: $PRINCIPAL_TYPE"

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would create access entry for: $PRINCIPAL_ARN"
        log_info "Would associate policy: $ACCESS_POLICY"
        exit 0
    fi

    # Create access entry
    log_step "Creating Access Entry"
    
    aws eks create-access-entry \
        --cluster-name "$CLUSTER_NAME" \
        --region "$REGION" \
        --principal-arn "$PRINCIPAL_ARN" \
        --type "$PRINCIPAL_TYPE" > /dev/null
    
    log_success "Access entry created"

    # Associate access policy
    log_step "Associating Access Policy"
    
    local policy_arn="arn:aws:eks::aws:cluster-access-policy/${ACCESS_POLICY}"
    
    aws eks associate-access-policy \
        --cluster-name "$CLUSTER_NAME" \
        --region "$REGION" \
        --principal-arn "$PRINCIPAL_ARN" \
        --access-scope type=cluster \
        --policy-arn "$policy_arn"
    
    log_success "Policy associated"

    log_step "Complete"
    log_info "Access entry configured for $PRINCIPAL_ARN"
    log_info "Verify: aws eks describe-access-entry --cluster-name $CLUSTER_NAME --principal-arn $PRINCIPAL_ARN"
    exit 0
}

main "$@"
