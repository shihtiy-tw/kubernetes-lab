#!/usr/bin/env bash
#
# check-versions.sh - Check and display versions of all required tools
#
# Usage:
#   ./scripts/check-versions.sh
#   ./scripts/check-versions.sh --help
#

set -euo pipefail

readonly VERSION="1.0.0"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m'

show_help() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Check and display versions of kubernetes-lab tools.

Options:
  --help          Show this help message
  --version       Show script version
  --json          Output in JSON format
  --quiet         Only show missing tools

EOF
}

check_tool() {
  local tool="$1"
  local version_cmd="$2"
  local min_version="${3:-}"
  
  if command -v "$tool" &>/dev/null; then
    local version
    version=$(eval "$version_cmd" 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓${NC} ${tool}: ${version}"
    return 0
  else
    echo -e "${RED}✗${NC} ${tool}: not installed"
    return 1
  fi
}

main() {
  local json_output=false
  local quiet=false
  
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
      --json)
        json_output=true
        shift
        ;;
      --quiet)
        quiet=true
        shift
        ;;
      *)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
    esac
  done
  
  echo ""
  echo -e "${BLUE}kubernetes-lab Tool Versions${NC}"
  echo "=============================="
  echo ""
  
  local missing=0
  
  echo -e "${GRAY}# Core Tools${NC}"
  check_tool "bash" "bash --version | head -1 | awk '{print \$4}' | cut -d'(' -f1" || ((missing++))
  check_tool "git" "git --version | awk '{print \$3}'" || ((missing++))
  check_tool "make" "make --version | head -1 | awk '{print \$3}'" || ((missing++))
  echo ""
  
  echo -e "${GRAY}# Kubernetes Tools${NC}"
  check_tool "kubectl" "kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null || kubectl version --client --short 2>/dev/null | awk '{print \$3}'" || ((missing++))
  check_tool "helm" "helm version --short | cut -d'+' -f1" || ((missing++))
  check_tool "kind" "kind version | awk '{print \$2}'" || ((missing++))
  check_tool "kustomize" "kustomize version --short 2>/dev/null || kustomize version | awk '{print \$1}'" || true
  echo ""
  
  echo -e "${GRAY}# AWS Tools${NC}"
  check_tool "aws" "aws --version 2>&1 | awk '{print \$1}' | cut -d'/' -f2" || true
  check_tool "eksctl" "eksctl version" || true
  echo ""
  
  echo -e "${GRAY}# Linting Tools${NC}"
  check_tool "shellcheck" "shellcheck --version | grep '^version:' | awk '{print \$2}'" || ((missing++))
  check_tool "yamllint" "yamllint --version | awk '{print \$2}'" || ((missing++))
  check_tool "hadolint" "hadolint --version | awk '{print \$4}'" || true
  echo ""
  
  echo -e "${GRAY}# Formatting Tools${NC}"
  check_tool "shfmt" "shfmt --version" || true
  check_tool "markdownlint" "markdownlint --version 2>/dev/null || echo 'unknown'" || true
  echo ""
  
  echo -e "${GRAY}# Testing Tools${NC}"
  check_tool "bats" "bats --version | awk '{print \$2}'" || true
  echo ""
  
  echo -e "${GRAY}# Development Tools${NC}"
  check_tool "pre-commit" "pre-commit --version | awk '{print \$2}'" || true
  check_tool "jq" "jq --version | cut -d'-' -f2" || true
  check_tool "yq" "yq --version | awk '{print \$NF}'" || true
  echo ""
  
  echo -e "${GRAY}# Terraform (Optional)${NC}"
  check_tool "terraform" "terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1 | awk '{print \$2}'" || true
  check_tool "tflint" "tflint --version | head -1 | awk '{print \$3}'" || true
  echo ""
  
  # Summary
  echo "=============================="
  if [[ $missing -gt 0 ]]; then
    echo -e "${RED}Missing required tools: $missing${NC}"
    echo "Run: ./scripts/install-deps.sh to install"
    exit 1
  else
    echo -e "${GREEN}All required tools installed!${NC}"
    exit 0
  fi
}

main "$@"
