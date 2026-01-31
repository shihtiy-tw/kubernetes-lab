#!/usr/bin/env bash
#
# setup-dev.sh - Set up kubernetes-lab development environment
#
# Usage:
#   ./scripts/setup-dev.sh
#   ./scripts/setup-dev.sh --help
#
# This script installs development dependencies and configures
# the local environment for kubernetes-lab development.
#

set -euo pipefail

# =============================================================================
# Constants
# =============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly VERSION="1.0.0"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[OK]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_section() {
  echo ""
  echo -e "${BLUE}=== $* ===${NC}"
  echo ""
}

# =============================================================================
# Help
# =============================================================================

show_help() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Set up kubernetes-lab development environment.

Options:
  --help          Show this help message
  --version       Show version
  --skip-optional Skip optional tool installation
  --check-only    Only check tools, don't install

Required Tools:
  - bash (>= 4.0)
  - kubectl
  - helm
  - kind
  - shellcheck
  - yamllint

Optional Tools:
  - pre-commit
  - bats
  - shfmt
  - markdownlint
  - terraform
  - tflint

EOF
}

# =============================================================================
# Tool Checks
# =============================================================================

check_command() {
  local cmd="$1"
  if command -v "$cmd" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

get_version() {
  local cmd="$1"
  case "$cmd" in
    bash) bash --version | head -1 | awk '{print $4}' | cut -d'(' -f1 ;;
    kubectl) kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null || echo "unknown" ;;
    helm) helm version --short 2>/dev/null | cut -d'+' -f1 ;;
    kind) kind version | awk '{print $2}' ;;
    shellcheck) shellcheck --version | grep '^version:' | awk '{print $2}' ;;
    yamllint) yamllint --version | awk '{print $2}' ;;
    pre-commit) pre-commit --version | awk '{print $2}' ;;
    bats) bats --version | awk '{print $2}' ;;
    shfmt) shfmt --version ;;
    markdownlint) markdownlint --version 2>/dev/null || echo "unknown" ;;
    terraform) terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || echo "unknown" ;;
    tflint) tflint --version | head -1 | awk '{print $3}' ;;
    *) echo "unknown" ;;
  esac
}

check_tool() {
  local tool="$1"
  local required="${2:-true}"
  
  if check_command "$tool"; then
    local version
    version=$(get_version "$tool")
    log_success "$tool ($version)"
    return 0
  else
    if [[ "$required" == "true" ]]; then
      log_error "$tool - NOT INSTALLED (required)"
      return 1
    else
      log_warn "$tool - not installed (optional)"
      return 0
    fi
  fi
}

# =============================================================================
# Main
# =============================================================================

main() {
  local skip_optional=false
  local check_only=false
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --help)
        show_help
        exit 0
        ;;
      --version)
        echo "setup-dev.sh version $VERSION"
        exit 0
        ;;
      --skip-optional)
        skip_optional=true
        shift
        ;;
      --check-only)
        check_only=true
        shift
        ;;
      *)
        log_error "Unknown option: $1"
        exit 1
        ;;
    esac
  done
  
  log_section "kubernetes-lab Development Environment Setup"
  
  local has_errors=false
  
  # Check required tools
  log_section "Required Tools"
  
  local required_tools=(
    "bash"
    "kubectl"
    "helm"
    "kind"
    "shellcheck"
    "yamllint"
  )
  
  for tool in "${required_tools[@]}"; do
    if ! check_tool "$tool" "true"; then
      has_errors=true
    fi
  done
  
  # Check optional tools
  if [[ "$skip_optional" != "true" ]]; then
    log_section "Optional Tools"
    
    local optional_tools=(
      "pre-commit"
      "bats"
      "shfmt"
      "markdownlint"
      "terraform"
      "tflint"
    )
    
    for tool in "${optional_tools[@]}"; do
      check_tool "$tool" "false" || true
    done
  fi
  
  if [[ "$check_only" == "true" ]]; then
    if [[ "$has_errors" == "true" ]]; then
      echo ""
      log_error "Some required tools are missing!"
      exit 1
    else
      echo ""
      log_success "All required tools are installed!"
      exit 0
    fi
  fi
  
  # Setup steps
  if [[ "$has_errors" == "true" ]]; then
    echo ""
    log_error "Cannot continue: required tools are missing."
    log_info "Install missing tools and run again."
    exit 1
  fi
  
  log_section "Setting Up Development Environment"
  
  # Install pre-commit hooks
  if check_command "pre-commit"; then
    log_info "Installing pre-commit hooks..."
    cd "$PROJECT_ROOT"
    pre-commit install || log_warn "Failed to install pre-commit hooks"
    pre-commit install --hook-type commit-msg || log_warn "Failed to install commit-msg hook"
    log_success "Pre-commit hooks installed"
  fi
  
  # Set git commit template
  if [[ -f "$PROJECT_ROOT/.gitmessage" ]]; then
    log_info "Setting git commit template..."
    git config --local commit.template .gitmessage
    log_success "Git commit template configured"
  fi
  
  # Verify project structure
  log_info "Verifying project structure..."
  local dirs_ok=true
  for dir in eks kind shared tests; do
    if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
      log_warn "Directory missing: $dir"
      dirs_ok=false
    fi
  done
  
  if [[ "$dirs_ok" == "true" ]]; then
    log_success "Project structure verified"
  fi
  
  # Final status
  log_section "Setup Complete"
  
  echo "Your development environment is ready!"
  echo ""
  echo "Quick start:"
  echo "  1. Create a Kind cluster:  ./kind/create-cluster.sh --name dev"
  echo "  2. Install an addon:       ./eks/addons/ingress-nginx/install.sh --help"
  echo "  3. Run tests:              make test"
  echo ""
  echo "For more information, see README.md"
}

main "$@"
