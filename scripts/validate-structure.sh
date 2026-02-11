#!/usr/bin/env bash
# Spec 001: Project Structure Validator
# Verifies adherence to the mandatory top-level structure
set -euo pipefail

VERSION="1.0.0"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --version          Show version"
    echo "  --help             Show this help"
}

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) echo "$VERSION"; exit 0 ;;
        --help) usage; exit 0 ;;
        *) log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
done

REQUIRED_DIRS=(
    ".opencode"
    ".specify"
    ".github"
    "aks"
    "docs"
    "eks"
    "gke"
    "kind"
    "scripts"
    "shared"
    "tests"
)

REQUIRED_FILES=(
    "AGENTS.md"
    "BACKLOG.md"
    "Makefile"
    "README.md"
)

ALLOWED_ITEMS=(
    "${REQUIRED_DIRS[@]}"
    "${REQUIRED_FILES[@]}"
    ".git"
    ".gitignore"
    ".dockerignore"
    ".editorconfig"
    ".gitattributes"
    ".gitmessage"
    ".hadolint.yaml"
    ".helmignore"
    ".markdownlint.json"
    ".pre-commit-config.yaml"
    ".shellcheckrc"
    ".yamllint"
    ".vscode"
    "LICENSE"
)

errors=0

log_info "Validating project structure..."

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        log_error "Missing mandatory directory: $dir"
        errors=$((errors + 1))
    fi
done

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        log_error "Missing mandatory file: $file"
        errors=$((errors + 1))
    fi
done

for item in * .*; do
    [[ "$item" == "." || "$item" == ".." ]] && continue
    
    item_clean="${item%/}"
    
    allowed=false
    for allowed_item in "${ALLOWED_ITEMS[@]}"; do
        if [[ "$item_clean" == "$allowed_item" ]]; then
            allowed=true
            break
        fi
    done
    
    if [[ "$allowed" == "false" ]]; then
        if [[ "$item_clean" == "CLAUDE.md" || "$item_clean" == "GEMINI.md" || "$item_clean" == ".claude" || "$item_clean" == ".gemini" || "$item_clean" == ".labtemplate" || "$item_clean" == ".progress.md" ]]; then
            log_info "Skipping agent/system specific item: $item_clean"
            continue
        fi
        
        log_error "Unauthorized top-level item: $item_clean"
        errors=$((errors + 1))
    fi
done

if [[ $errors -gt 0 ]]; then
    log_error "Validation failed with $errors error(s)."
    exit 1
else
    log_info "Validation successful! Structure matches Spec 001."
    exit 0
fi
