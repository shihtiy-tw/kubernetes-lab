#!/usr/bin/env bash
# Common utilities for k8s lab scripts
# CLI 12-Factor Compliant

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging - separate stdout/stderr
log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&1; }
log_success() { echo -e "${GREEN}[OK]${NC} $*" >&1; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "\n${YELLOW}=== $* ===${NC}" >&1; }

# Dependency check
check_binary() {
    local binary=$1
    if ! command -v "$binary" &> /dev/null; then
        log_error "Dependency missing: $binary"
        return 1
    fi
    return 0
}

# Export colors for use in other scripts if needed
export BLUE GREEN YELLOW RED NC
