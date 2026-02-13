#!/usr/bin/env bash
# Unified addon installation wrapper
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source utilities
# shellcheck source=scripts/utils/common.sh
source "${SCRIPT_DIR}/utils/common.sh"
# shellcheck source=scripts/utils/validate-platform.sh
source "${SCRIPT_DIR}/utils/validate-platform.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") --platform PLATFORM --addon ADDON [OPTIONS]

Unified wrapper for installing Kubernetes addons.

OPTIONS:
    --platform PLATFORM    Target platform (kind, eks, gke, aks)
    --addon ADDON          Addon name
    --cluster CLUSTER      Target cluster name
    --region REGION        Cloud region (if needed)
    --dry-run              Show the command that would be executed
    -h, --help             Show this help message
    -v, --version          Show script version

EXAMPLES:
    # Install Ingress NGINX on EKS
    $(basename "$0") --platform eks --addon ingress-nginx-controller --cluster my-cluster

    # Install shared plugin on Kind
    $(basename "$0") --platform kind --addon ingress-nginx --cluster kind-dev
EOF
}

# Defaults
PLATFORM="${K8S_PLATFORM:-}"
ADDON=""
CLUSTER=""
REGION="${AWS_REGION:-${GOOGLE_REGION:-${AZURE_LOCATION:-}}}"
DRY_RUN=false
FORWARD_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --addon)
            ADDON="$2"
            shift 2
            ;;
        --cluster)
            CLUSTER="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
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
            echo "$(basename "$0") version ${SCRIPT_VERSION}"
            exit 0
            ;;
        *)
            FORWARD_ARGS+=("$1")
            shift
            ;;
    esac
done

# Validation
validate_platform "$PLATFORM" || exit 1
if [[ -z "$ADDON" ]]; then
    log_error "--addon is required"
    exit 1
fi
validate_dependencies "$PLATFORM" || exit 1

log_step "Searching for Addon: $ADDON"

# Search paths (platform-specific first)
PATHS=(
    "${PLATFORM}/addons/${ADDON}"
    "shared/plugins/${ADDON}"
)

INSTALL_SCRIPT=""

for p in "${PATHS[@]}"; do
    if [[ -f "${PROJECT_ROOT}/${p}/install.sh" ]]; then
        INSTALL_SCRIPT="${p}/install.sh"
        break
    elif [[ -f "${PROJECT_ROOT}/${p}/build.sh" ]]; then
        INSTALL_SCRIPT="${p}/build.sh"
        break
    fi
done

if [[ -z "$INSTALL_SCRIPT" ]]; then
    log_error "Addon '$ADDON' not found for platform '$PLATFORM'."
    exit 1
fi

log_info "Found installation script: $INSTALL_SCRIPT"

# Context Management
if [[ -n "$CLUSTER" ]]; then
    log_step "Context Management"
    CONTEXT_NAME="$CLUSTER"
    if [[ "$PLATFORM" == "kind" ]] && [[ ! "$CLUSTER" =~ ^kind- ]]; then
        CONTEXT_NAME="kind-$CLUSTER"
    fi
    
    if kubectl config get-contexts "$CONTEXT_NAME" &> /dev/null; then
        log_info "Switching to context: $CONTEXT_NAME"
        if ! $DRY_RUN; then
            kubectl config use-context "$CONTEXT_NAME" > /dev/null
        fi
    else
        log_warn "Context '$CONTEXT_NAME' not found. Underlying script may fail if it expects it."
    fi
fi

# Prepare arguments for forwarding
PLATFORM_ARGS=()
if [[ "$INSTALL_SCRIPT" != shared* ]]; then
    [[ -n "$CLUSTER" ]] && PLATFORM_ARGS+=("--cluster" "$CLUSTER")
    [[ -n "$REGION" ]] && PLATFORM_ARGS+=("--region" "$REGION")
fi

# Execute
if $DRY_RUN; then
    log_info "[DRY RUN] Would execute: ./${INSTALL_SCRIPT} ${PLATFORM_ARGS[*]} ${FORWARD_ARGS[*]}"
    exit 0
fi

cd "$PROJECT_ROOT"
exec "./${INSTALL_SCRIPT}" "${PLATFORM_ARGS[@]}" "${FORWARD_ARGS[@]}"
