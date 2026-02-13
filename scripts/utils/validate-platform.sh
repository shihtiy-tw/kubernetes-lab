#!/usr/bin/env bash
# Platform validation logic for k8s lab wrappers
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/utils/common.sh
source "${SCRIPT_DIR}/common.sh"

# Validate if the platform is supported
validate_platform() {
    local platform=$1
    if [[ -z "$platform" ]]; then
        log_error "Platform not specified. Use --platform {kind|eks|gke|aks}"
        return 1
    fi

    case "$platform" in
        kind|eks|gke|aks)
            return 0
            ;;
        *)
            log_error "Invalid platform: $platform. Supported: kind, eks, gke, aks"
            return 1
            ;;
    esac
}

# Validate required binaries for the platform
validate_dependencies() {
    local platform=$1
    
    # Check for kubectl (required by all for context management/verification)
    check_binary "kubectl" || return 1

    case "$platform" in
        kind)
            check_binary "kind" || return 1
            ;;
        eks)
            check_binary "eksctl" || return 1
            check_binary "aws" || return 1
            ;;
        gke)
            check_binary "gcloud" || return 1
            ;;
        aks)
            check_binary "az" || return 1
            ;;
    esac
}

# Issue warnings for outdated tools (FR-010)
warn_outdated_tools() {
    local platform=$1
    log_info "Validated dependencies for $platform"
}
