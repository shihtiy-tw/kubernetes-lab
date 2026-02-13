#!/usr/bin/env bash
# Unified log retrieval wrapper
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
Usage: $(basename "$0") [OPTIONS] [KUBECTL_LOGS_ARGS]

Unified wrapper for retrieving logs from Kubernetes pods.

OPTIONS:
    --platform PLATFORM    Target platform (kind, eks, gke, aks)
    --cluster CLUSTER      Target cluster name
    --deployment DEPLOY    Filter by deployment name
    --dry-run              Show the command that would be executed
    -h, --help             Show this help message
    -v, --version          Show script version

All other arguments are forwarded to 'kubectl logs'.

EXAMPLES:
    # Get logs from a deployment
    $(basename "$0") --platform eks --cluster my-lab --deployment nginx

    # Follow logs with specific context
    $(basename "$0") --platform kind --cluster dev --deployment api -f
EOF
}

# Defaults
PLATFORM="${K8S_PLATFORM:-}"
CLUSTER=""
DEPLOYMENT=""
DRY_RUN=false
FORWARD_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --cluster)
            CLUSTER="$2"
            shift 2
            ;;
        --deployment)
            DEPLOYMENT="$2"
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

# Context Management
if [[ -n "$PLATFORM" && -n "$CLUSTER" ]]; then
    validate_platform "$PLATFORM" || exit 1
    CONTEXT_NAME="$CLUSTER"
    if [[ "$PLATFORM" == "kind" ]] && [[ ! "$CLUSTER" =~ ^kind- ]]; then
        CONTEXT_NAME="kind-$CLUSTER"
    fi
    
    if kubectl config get-contexts "$CONTEXT_NAME" &> /dev/null; then
        log_info "Using context: $CONTEXT_NAME"
        FORWARD_ARGS+=("--context" "$CONTEXT_NAME")
    fi
fi

# Prepare kubectl command
KCMD=("kubectl" "logs")
if [[ -n "$DEPLOYMENT" ]]; then
    KCMD+=("deployment/${DEPLOYMENT}")
fi

# Execute
if $DRY_RUN; then
    log_info "[DRY RUN] Would execute: ${KCMD[*]} ${FORWARD_ARGS[*]}"
    exit 0
fi

exec "${KCMD[@]}" "${FORWARD_ARGS[@]}"
