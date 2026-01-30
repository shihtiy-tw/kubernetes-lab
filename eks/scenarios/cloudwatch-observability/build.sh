#!/usr/bin/env bash
# CloudWatch Observability Configuration Scenario
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

Configure CloudWatch Observability addon with custom settings.

OPTIONS:
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --config FILE         Configuration file (default: disk-memory.json)
    --dry-run             Show what would be configured
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Apply default configuration
    $(basename "$0")

    # Apply custom configuration
    $(basename "$0") --config my-config.json

    # Dry run
    $(basename "$0") --dry-run
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
ADDON_NAME="amazon-cloudwatch-observability"

# Defaults
CLUSTER_NAME=""
REGION=""
CONFIG_FILE="disk-memory.json"
DRY_RUN=false

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
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
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

# Main
main() {
    get_cluster_info
    cd "$SCRIPT_DIR"

    log_step "Environment"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $REGION"
    log_info "Config File: $CONFIG_FILE"

    # Check config file
    local config_path=""
    if [[ -f "$CONFIG_FILE" ]]; then
        config_path="$CONFIG_FILE"
    elif [[ -f "${SCRIPT_DIR}/${CONFIG_FILE}" ]]; then
        config_path="${SCRIPT_DIR}/${CONFIG_FILE}"
    else
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would update addon: $ADDON_NAME"
        log_info "Config file: $config_path"
        log_info "Conflict resolution: PRESERVE"
        exit 0
    fi

    log_step "Updating CloudWatch Configuration"
    aws eks update-addon \
        --cluster-name "$CLUSTER_NAME" \
        --addon-name "$ADDON_NAME" \
        --configuration-values "file://${config_path}" \
        --resolve-conflicts PRESERVE \
        --region "$REGION"

    log_success "Configuration updated"

    log_step "Complete"
    log_info "CloudWatch Observability addon reconfigured"
    log_info "Check status: aws eks describe-addon --cluster-name $CLUSTER_NAME --addon-name $ADDON_NAME"
    exit 0
}

main "$@"
