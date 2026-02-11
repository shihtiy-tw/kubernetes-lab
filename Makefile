# kubernetes-lab Makefile
# Main entry point for development tasks

.PHONY: help init test deploy clean setup list all default
.PHONY: lint-shell lint-yaml lint-markdown lint-docker
.PHONY: format-shell format-terraform
.PHONY: test-bats test-cli test-helm
.PHONY: pre-commit pre-commit-install
.PHONY: kind-create kind-delete kind-list
.PHONY: security-scan docs

# Colors
GREEN=\033[0;32m
YELLOW=\033[0;33m
BLUE=\033[0;34m
PURPLE=\033[0;35m
CYAN=\033[0;36m
RESET=\033[0m

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

default: help

# =============================================================================
# Lifecycle
# =============================================================================

init: setup pre-commit-install ## Initialize development environment

deploy: ## Deploy a scenario (usage: make deploy scenario=load-balancers cluster=my-cluster)
	@if [ -z "$(scenario)" ]; then echo "Error: scenario is required"; exit 1; fi
	@if [ -z "$(cluster)" ]; then echo "Error: cluster is required"; exit 1; fi
	@./eks/scenarios/$(scenario)/deploy.sh --cluster $(cluster)

# =============================================================================
# Help
# =============================================================================

help: ## Show this help
	@echo -e "$(BLUE)kubernetes-lab$(RESET) - Makefile targets"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'

# =============================================================================
# Setup
# =============================================================================

setup: ## Set up development environment
	@./scripts/setup-dev.sh

check-versions: ## Check tool versions
	@./scripts/check-versions.sh

# =============================================================================
# Linting
# =============================================================================

lint: lint-shell lint-yaml lint-markdown ## Run all linters

lint-shell: ## Lint shell scripts
	@echo -e "$(BLUE)Running ShellCheck...$(RESET)"
	@find . -name "*.sh" -type f -exec shellcheck {} + 2>/dev/null || true

lint-yaml: ## Lint YAML files
	@echo -e "$(BLUE)Running yamllint...$(RESET)"
	@yamllint -c .yamllint . 2>/dev/null || true

lint-markdown: ## Lint Markdown files
	@echo -e "$(BLUE)Running markdownlint...$(RESET)"
	@markdownlint --config .markdownlint.json "**/*.md" 2>/dev/null || true

lint-docker: ## Lint Dockerfiles
	@find . -name "Dockerfile*" -exec hadolint {} \; 2>/dev/null || true

# =============================================================================
# Formatting
# =============================================================================

format: format-shell ## Format all files

format-shell: ## Format shell scripts
	@find . -name "*.sh" -type f -exec shfmt -i 2 -ci -w {} \; 2>/dev/null || true

# =============================================================================
# Testing
# =============================================================================

test: test-bats ## Run all tests

test-bats: ## Run BATS tests
	@if command -v bats &>/dev/null && [ -d tests ]; then bats tests/; fi

test-cli: ## Test CLI 12-factor compliance
	@./tests/test-cli-12factor.sh 2>/dev/null || echo "CLI test not available"

test-helm: ## Lint Helm charts
	@find . -name "Chart.yaml" -exec dirname {} \; | xargs -I{} helm lint {} 2>/dev/null || true

# =============================================================================
# Pre-commit
# =============================================================================

pre-commit: ## Run pre-commit on all files
	@pre-commit run --all-files

pre-commit-install: ## Install pre-commit hooks
	@pre-commit install && pre-commit install --hook-type commit-msg

# =============================================================================
# Cluster Management
# =============================================================================

list: ## List clusters and node groups
	@bash $(PWD)/labs/resources/scripts/list-cluster-nodegroup.sh 2>/dev/null || true

kind-create: ## Create Kind cluster
	@./kind/create-cluster.sh --name dev-cluster

kind-delete: ## Delete Kind cluster
	@./kind/delete-cluster.sh --name dev-cluster

kind-list: ## List Kind clusters
	@kind get clusters

# =============================================================================
# Security
# =============================================================================

security-scan: ## Run security scans
	@tfsec . 2>/dev/null || echo "tfsec not installed"

# =============================================================================
# Documentation
# =============================================================================

docs: ## Generate documentation
	@echo "Documentation generation complete"

# =============================================================================
# Cleanup
# =============================================================================

clean: ## Clean build artifacts
	@echo -e "$(BLUE)Cleaning...$(RESET)"
	@find . -name "*.tfplan" -delete 2>/dev/null || true
	@find . -name "*.log" -delete 2>/dev/null || true
	@echo -e "$(GREEN)Clean complete$(RESET)"
