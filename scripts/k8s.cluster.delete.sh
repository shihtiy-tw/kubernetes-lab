#!/usr/bin/env bash
# Unified cluster deletion wrapper
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
Usage: $(basename "$0") --platform {kind|eks|gke|aks} --name NAME [OPTIONS]

Unified wrapper for deleting Kubernetes clusters.

OPTIONS:
    --platform PLATFORM    Target platform (kind, eks, gke, aks)
    --name NAME            Cluster name
    --region REGION        Cloud region (maps to --location for AKS)
    --project PROJECT      Cloud project or resource group
    --force, --yes         Skip confirmation prompt
    --dry-run              Show the command that would be executed
    -h, --help             Show this help message
    -v, --version          Show script version

EXAMPLES:
    # Delete cluster with confirmation
    $(basename "$0") --platform kind --name dev

    # Force delete without confirmation
    $(basename "$0") --platform eks --name lab --yes
EOF
}

# Defaults
PLATFORM="${K8S_PLATFORM:-}"
NAME=""
REGION="${AWS_REGION:-${GOOGLE_REGION:-${AZURE_LOCATION:-}}}"
PROJECT="${GOOGLE_PROJECT:-}"
FORCE=false
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
        --project)
            PROJECT="$2"
            shift 2
            ;;
        --force|--yes)
            FORCE=true
            shift
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
if [[ -z "$NAME" ]]; then
    log_error "--name is required"
    exit 1
fi
validate_dependencies "$PLATFORM" || exit 1

# Confirmation
if [[ "$FORCE" = false && "$DRY_RUN" = false ]]; then
    echo -e "${RED}${YELLOW}!!! WARNING: DESTRUCTIVE OPERATION !!!${NC}"
    read -p "Are you sure you want to delete cluster '$NAME' on platform '$PLATFORM'? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deletion cancelled."
        exit 0
    fi
fi

log_step "Dispatching Cluster Deletion"
log_info "Platform: $PLATFORM"
log_info "Cluster: $NAME"

# Map to platform-specific scripts and flags
PLATFORM_SCRIPT=""
PLATFORM_ARGS=("--name" "$NAME")

case "$PLATFORM" in
    kind)
        PLATFORM_SCRIPT="kind"
        PLATFORM_ARGS=("delete" "cluster" "--name" "$NAME")
        ;;
    eks)
        PLATFORM_SCRIPT="eksctl"
        PLATFORM_ARGS=("delete" "cluster" "--name" "$NAME")
        [[ -n "$REGION" ]] && PLATFORM_ARGS+=("--region" "$REGION")
        ;;
    gke)
        PLATFORM_SCRIPT="gke/clusters/gke-cluster-delete.sh"
        [[ -n "$REGION" ]] && PLATFORM_ARGS+=("--region" "$REGION")
        [[ -n "$PROJECT" ]] && PLATFORM_ARGS+=("--project" "$PROJECT")
        PLATFORM_ARGS+=("--force")
        ;;
    aks)
        PLATFORM_SCRIPT="aks/clusters/aks-cluster-delete.sh"
        [[ -n "$PROJECT" ]] && PLATFORM_ARGS+=("--resource-group" "$PROJECT")
        ;;
esac

# Execute
if $DRY_RUN; then
    log_info "[DRY RUN] Would execute: ${PLATFORM_SCRIPT} ${PLATFORM_ARGS[*]} ${FORWARD_ARGS[*]}"
    exit 0
fi

cd "$PROJECT_ROOT"
if [[ "$PLATFORM_SCRIPT" == */* ]]; then
    exec "./${PLATFORM_SCRIPT}" "${PLATFORM_ARGS[@]}" "${FORWARD_ARGS[@]}"
else
    exec "${PLATFORM_SCRIPT}" "${PLATFORM_ARGS[@]}" "${FORWARD_ARGS[@]}"
fi
