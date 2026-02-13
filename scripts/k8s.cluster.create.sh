#!/usr/bin/env bash
# Unified cluster creation wrapper
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
Usage: $(basename "$0") --platform {kind|eks|gke|aks} [OPTIONS]

Unified wrapper for creating Kubernetes clusters across multiple providers.

OPTIONS:
    --platform PLATFORM    Target platform (kind, eks, gke, aks)
    --name NAME            Base cluster name (default: lab)
    --region REGION        Cloud region (maps to --location for AKS)
    --version VER          Kubernetes version (e.g., 1.29) (default: latest)
    --config TYPE          Config profile: minimal, standard, full (default: standard)
    --dry-run              Show the command that would be executed
    -h, --help             Show this help message
    -v, --version          Show script version

EXAMPLES:
    # Create Kind cluster
    $(basename "$0") --platform kind --name dev

    # Create EKS cluster in specific region
    $(basename "$0") --platform eks --name lab --region us-west-2 --version 1.29
EOF
}

# Defaults
PLATFORM="${K8S_PLATFORM:-}"
NAME="lab"
REGION="${AWS_REGION:-${GOOGLE_REGION:-${AZURE_LOCATION:-}}}"
VERSION="latest"
CONFIG="standard"
DRY_RUN=false
FORWARD_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --name)
            NAME="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --version)
            if [[ $# -gt 1 && "$2" != -* ]]; then
                VERSION="$2"
                shift 2
            else
                echo "$(basename "$0") version ${SCRIPT_VERSION}"
                exit 0
            fi
            ;;
        *)
            FORWARD_ARGS+=("$1")
            shift
            ;;
    esac
done

# Validation
validate_platform "$PLATFORM" || exit 1
validate_dependencies "$PLATFORM" || exit 1
warn_outdated_tools "$PLATFORM"

# Normalize version for naming (e.g. 1.29 -> 1-29)
NORM_VERSION=$(echo "$VERSION" | tr '.' '-')
FULL_NAME="${PLATFORM}-${NORM_VERSION}-${CONFIG}-${NAME}"

log_step "Dispatching Cluster Creation"
log_info "Platform: $PLATFORM"
log_info "Unified Name: $FULL_NAME"

# Map to platform-specific scripts and flags
PLATFORM_SCRIPT=""
PLATFORM_ARGS=("--name" "$FULL_NAME")

case "$PLATFORM" in
    kind)
        PLATFORM_SCRIPT="kind/clusters/kind-cluster-create.sh"
        [[ "$VERSION" != "latest" ]] && PLATFORM_ARGS+=("--k8s-version" "$VERSION")
        ;;
    eks)
        PLATFORM_SCRIPT="eks/clusters/create.sh"
        [[ -n "$REGION" ]] && PLATFORM_ARGS+=("--region" "$REGION")
        PLATFORM_ARGS+=("--version" "$VERSION" "--config" "$CONFIG")
        ;;
    gke)
        PLATFORM_SCRIPT="gke/clusters/create.sh"
        [[ -n "$REGION" ]] && PLATFORM_ARGS+=("--region" "$REGION")
        [[ "$VERSION" != "latest" ]] && PLATFORM_ARGS+=("--k8s-version" "$VERSION")
        ;;
    aks)
        PLATFORM_SCRIPT="aks/clusters/create.sh"
        [[ -n "$REGION" ]] && PLATFORM_ARGS+=("--location" "$REGION")
        [[ "$VERSION" != "latest" ]] && PLATFORM_ARGS+=("--k8s-version" "$VERSION")
        # For AKS, we use name as resource group too if not provided
        PLATFORM_ARGS+=("--resource-group" "$FULL_NAME")
        ;;
esac

# Execute
if $DRY_RUN; then
    log_info "[DRY RUN] Would execute: ./${PLATFORM_SCRIPT} ${PLATFORM_ARGS[*]} ${FORWARD_ARGS[*]}"
    exit 0
fi

cd "$PROJECT_ROOT"
exec "./${PLATFORM_SCRIPT}" "${PLATFORM_ARGS[@]}" "${FORWARD_ARGS[@]}"
