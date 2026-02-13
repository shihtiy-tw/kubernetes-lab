#!/usr/bin/env bash
# Unified scenario deployment wrapper
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
Usage: $(basename "$0") --platform PLATFORM --scenario SCENARIO [OPTIONS]

Unified wrapper for deploying laboratory scenarios.

OPTIONS:
    --platform PLATFORM    Target platform (kind, eks, gke, aks)
    --scenario SCENARIO    Scenario name
    --cluster CLUSTER      Target cluster name
    --dry-run              Show the command that would be executed
    -h, --help             Show this help message
    -v, --version          Show script version

EXAMPLES:
    # Deploy scenario on EKS
    $(basename "$0") --platform eks --scenario load-balancers/alb-https --cluster my-lab

    # Deploy scenario on AKS (manifest-based fallback)
    $(basename "$0") --platform aks --scenario appgw-ingress --cluster my-aks
EOF
}

# Defaults
PLATFORM="${K8S_PLATFORM:-}"
SCENARIO=""
CLUSTER=""
DRY_RUN=false
FORWARD_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --scenario)
            SCENARIO="$2"
            shift 2
            ;;
        --cluster)
            CLUSTER="$2"
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
if [[ -z "$SCENARIO" ]]; then
    log_error "--scenario is required"
    exit 1
fi
validate_dependencies "$PLATFORM" || exit 1

log_step "Deploying Scenario: $SCENARIO"

# Path to scenario
SCENARIO_PATH="${PLATFORM}/scenarios/${SCENARIO}"

if [[ ! -d "${PROJECT_ROOT}/${SCENARIO_PATH}" ]]; then
    log_error "Scenario '$SCENARIO' not found for platform '$PLATFORM'."
    exit 1
fi

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
        log_warn "Context '$CONTEXT_NAME' not found."
    fi
fi

# Determine deployment method
DEPLOY_CMD=""
if [[ -f "${PROJECT_ROOT}/${SCENARIO_PATH}/deploy.sh" ]]; then
    DEPLOY_CMD="./${SCENARIO_PATH}/deploy.sh"
elif [[ -f "${PROJECT_ROOT}/${SCENARIO_PATH}/build.sh" ]]; then
    DEPLOY_CMD="./${SCENARIO_PATH}/build.sh"
elif [[ -d "${PROJECT_ROOT}/${SCENARIO_PATH}/manifests" ]]; then
    DEPLOY_CMD="kubectl apply -f ./${SCENARIO_PATH}/manifests/"
else
    log_error "No deployment method found for scenario '$SCENARIO'."
    exit 1
fi

log_info "Deployment method: $DEPLOY_CMD"

# Prepare arguments
PLATFORM_ARGS=()
if [[ "$DEPLOY_CMD" != kubectl* ]]; then
    [[ -n "$CLUSTER" ]] && PLATFORM_ARGS+=("--cluster" "$CLUSTER")
fi

# Execute
if $DRY_RUN; then
    log_info "[DRY RUN] Would execute: ${DEPLOY_CMD} ${PLATFORM_ARGS[*]} ${FORWARD_ARGS[*]}"
    exit 0
fi

cd "$PROJECT_ROOT"
if [[ "$DEPLOY_CMD" == kubectl* ]]; then
    # shellcheck disable=SC2086
    exec $DEPLOY_CMD "${FORWARD_ARGS[@]}"
else
    exec "$DEPLOY_CMD" "${PLATFORM_ARGS[@]}" "${FORWARD_ARGS[@]}"
fi
