#!/usr/bin/env bash
#
# install-deps.sh - Install development dependencies for kubernetes-lab
#
# Usage:
#   ./scripts/install-deps.sh
#   ./scripts/install-deps.sh --help
#
# This script helps install common development tools.
# It supports Linux (apt, dnf) and macOS (brew).
#

set -euo pipefail

readonly VERSION="1.0.0"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

show_help() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Install kubernetes-lab development dependencies.

Options:
  --help          Show this help message
  --version       Show version
  --dry-run       Show what would be installed

Supported Platforms:
  - macOS (using Homebrew)
  - Ubuntu/Debian (using apt)
  - Fedora/RHEL (using dnf)

EOF
}

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ -f /etc/os-release ]]; then
    source /etc/os-release
    case "$ID" in
      ubuntu|debian) echo "debian" ;;
      fedora|rhel|centos) echo "rhel" ;;
      *) echo "unknown" ;;
    esac
  else
    echo "unknown"
  fi
}

install_macos() {
  log_info "Installing dependencies with Homebrew..."
  
  local packages=(
    kubectl
    helm
    kind
    shellcheck
    yamllint
    pre-commit
    bats-core
    shfmt
    jq
    yq
  )
  
  for pkg in "${packages[@]}"; do
    if brew list "$pkg" &>/dev/null; then
      log_success "$pkg already installed"
    else
      log_info "Installing $pkg..."
      brew install "$pkg"
    fi
  done
}

install_debian() {
  log_info "Installing dependencies with apt..."
  
  # Base packages
  sudo apt-get update
  sudo apt-get install -y \
    curl \
    git \
    make \
    shellcheck \
    yamllint \
    jq \
    python3-pip
  
  # kubectl
  if ! command -v kubectl &>/dev/null; then
    log_info "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
  fi
  
  # helm
  if ! command -v helm &>/dev/null; then
    log_info "Installing helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi
  
  # kind
  if ! command -v kind &>/dev/null; then
    log_info "Installing kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
  fi
  
  # pre-commit
  pip3 install --user pre-commit
  
  # bats
  if ! command -v bats &>/dev/null; then
    log_info "Installing bats..."
    git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
    sudo /tmp/bats-core/install.sh /usr/local
    rm -rf /tmp/bats-core
  fi
  
  # shfmt
  if ! command -v shfmt &>/dev/null; then
    log_info "Installing shfmt..."
    GO111MODULE=on go install mvdan.cc/sh/v3/cmd/shfmt@latest 2>/dev/null || \
      log_warn "shfmt requires Go - install manually"
  fi
}

install_rhel() {
  log_info "Installing dependencies with dnf..."
  
  sudo dnf install -y \
    curl \
    git \
    make \
    ShellCheck \
    python3-pip \
    jq
  
  # Similar to debian for remaining tools
  pip3 install --user yamllint pre-commit
  
  log_warn "For kubectl, helm, kind - follow manual installation steps"
}

main() {
  local dry_run=false
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      --help)
        show_help
        exit 0
        ;;
      --version)
        echo "$VERSION"
        exit 0
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      *)
        log_error "Unknown option: $1"
        exit 1
        ;;
    esac
  done
  
  local os
  os=$(detect_os)
  
  log_info "Detected OS: $os"
  
  if [[ "$dry_run" == "true" ]]; then
    log_info "[DRY RUN] Would install dependencies for: $os"
    exit 0
  fi
  
  case "$os" in
    macos)
      if ! command -v brew &>/dev/null; then
        log_error "Homebrew not installed. Install from https://brew.sh"
        exit 1
      fi
      install_macos
      ;;
    debian)
      install_debian
      ;;
    rhel)
      install_rhel
      ;;
    *)
      log_error "Unsupported OS. Please install dependencies manually."
      log_info "Required tools: kubectl, helm, kind, shellcheck, yamllint"
      exit 1
      ;;
  esac
  
  log_success "Dependencies installed!"
  log_info "Run './scripts/check-versions.sh' to verify installation"
}

main "$@"
