# Naming Conventions

Consistent naming conventions across the kubernetes-lab codebase.

## Table of Contents

- [General Principles](#general-principles)
- [Files and Directories](#files-and-directories)
- [Kubernetes Resources](#kubernetes-resources)
- [Shell Scripts](#shell-scripts)
- [Variables](#variables)
- [Git](#git)

---

## General Principles

1. **Be descriptive**: Names should convey purpose
2. **Be consistent**: Same patterns throughout
3. **Be concise**: Avoid unnecessary words
4. **Use lowercase**: With separators as needed
5. **Avoid abbreviations**: Unless widely understood (e.g., k8s, eks)

---

## Files and Directories

### Directory Names

```
# Use lowercase with hyphens
eks/
kind/
ingress-nginx/
cert-manager/

# Group by function
addons/          # Kubernetes addons
scenarios/       # Deployment scenarios
utils/           # Utility functions
tests/           # Test files
docs/            # Documentation
examples/        # Example configurations
scripts/         # Helper scripts
monitoring/      # Observability configs
```

### File Names

```bash
# Scripts: lowercase with hyphens, .sh extension
install-addon.sh
setup-cluster.sh
deploy-scenario.sh

# Configuration: lowercase, descriptive
values.yaml
values-production.yaml
kustomization.yaml

# Documentation: UPPERCASE for special files
README.md
CHANGELOG.md
CONTRIBUTING.md
LICENSE

# Documentation: lowercase for guides
quickstart.md
troubleshooting.md
architecture.md

# Tests: suffix with _test or .test
addon_test.sh
install.bats
scenario.kuttl-test.yaml
```

---

## Kubernetes Resources

### Metadata Labels

Use the [standard Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/):

```yaml
labels:
  # Recommended labels
  app.kubernetes.io/name: ingress-nginx
  app.kubernetes.io/instance: ingress-nginx-production
  app.kubernetes.io/version: "4.8.0"
  app.kubernetes.io/component: controller
  app.kubernetes.io/part-of: ingress-stack
  app.kubernetes.io/managed-by: helm
  
  # Custom labels for this lab
  kubernetes-lab/addon: ingress-nginx
  kubernetes-lab/scenario: production
  kubernetes-lab/environment: staging
```

### Resource Names

```yaml
# Format: [app]-[component]-[qualifier]
# Examples:
name: ingress-nginx-controller
name: prometheus-server
name: grafana-dashboard
name: karpenter-controller

# ConfigMaps/Secrets: suffix with -config or -secret
name: app-config
name: app-secret
name: db-credentials

# ServiceAccounts: suffix with -sa or no suffix
name: karpenter
name: external-dns-sa
```

### Namespaces

```yaml
# Use descriptive, lowercase names
namespace: ingress-nginx
namespace: monitoring
namespace: kube-system
namespace: cert-manager

# Environment-specific
namespace: app-production
namespace: app-staging
```

---

## Shell Scripts

### Function Names

```bash
# Use lowercase with underscores
# Verb-noun pattern

# Good
function install_addon() { }
function create_cluster() { }
function validate_prerequisites() { }
function teardown_resources() { }

# Boolean checks: is_, has_, can_ prefix
function is_cluster_ready() { }
function has_required_tools() { }
function can_connect_to_api() { }

# Internal functions: prefix with underscore
function _parse_arguments() { }
function _validate_input() { }
function _cleanup_temp_files() { }
```

### Variable Names

```bash
# Constants: UPPER_SNAKE_CASE with readonly
readonly SCRIPT_DIR
readonly DEFAULT_VERSION
readonly MAX_RETRIES

# Environment variables: UPPER_SNAKE_CASE
export CLUSTER_NAME
export AWS_REGION
export KUBECONFIG

# Local variables: lower_snake_case
local cluster_name
local node_count
local is_ready

# Loop variables: short, descriptive
for addon in "${addons[@]}"; do
for node in $(kubectl get nodes -o name); do
for i in {1..5}; do
```

---

## Variables

### Script Arguments

```bash
# Long flags: descriptive, with hyphens
--cluster-name
--node-count
--dry-run
--force
--version
--help

# Environment variables from flags
CLUSTER_NAME      # from --cluster-name
NODE_COUNT        # from --node-count
DRY_RUN          # from --dry-run

# Boolean flags: no value needed
--dry-run        # Sets DRY_RUN=true
--force          # Sets FORCE=true
--verbose        # Sets VERBOSE=true
```

### Terraform Variables

```hcl
# Input variables: snake_case
variable "cluster_name" { }
variable "node_instance_types" { }
variable "vpc_cidr_block" { }

# Local values: snake_case
locals {
  cluster_oidc_issuer = "..."
  common_tags = { }
}

# Output values: snake_case
output "cluster_endpoint" { }
output "cluster_certificate_authority" { }
```

---

## Git

### Branch Names

```bash
# Format: type/description
feature/add-karpenter
bugfix/fix-ingress-annotations
docs/update-readme
refactor/cli-12factor
chore/update-dependencies

# Types:
# - feature: New functionality
# - bugfix: Bug fixes
# - docs: Documentation only
# - refactor: Code refactoring
# - chore: Maintenance tasks
# - test: Test additions/changes
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format: type(scope): description

# Types
feat:      # New feature
fix:       # Bug fix
docs:      # Documentation
style:     # Formatting (no code change)
refactor:  # Code refactoring
test:      # Tests
chore:     # Maintenance
perf:      # Performance
ci:        # CI/CD changes

# Examples
feat(addons): add karpenter support
fix(eks): correct security group rules
docs(readme): update installation steps
refactor(scenarios): apply CLI 12-factor
chore(deps): update helm charts
ci(github): add lint workflow

# With body
feat(addons): add ingress-nginx addon

Add NGINX Ingress Controller as an installable addon.
- Implements --install, --uninstall flags
- Includes --dry-run support
- Adds values customization via --values flag

Closes #42
```

### Tag Names

```bash
# Semantic versioning
v1.0.0
v1.2.3
v2.0.0-rc.1
v2.0.0-beta.2

# Format: v{major}.{minor}.{patch}[-prerelease]
```

---

## Quick Reference

| Context | Convention | Example |
|---------|------------|---------|
| Directory | lowercase-hyphen | `ingress-nginx/` |
| Script file | lowercase-hyphen.sh | `install-addon.sh` |
| Bash function | lowercase_underscore | `install_addon()` |
| Bash constant | UPPER_SNAKE | `readonly MAX_RETRIES` |
| Bash local var | lower_snake | `local node_count` |
| K8s resource | lowercase-hyphen | `ingress-nginx-controller` |
| K8s namespace | lowercase-hyphen | `cert-manager` |
| Terraform var | lower_snake | `cluster_name` |
| Git branch | type/description | `feature/add-karpenter` |
| Git commit | type(scope): msg | `feat(addons): add support` |
| Git tag | vX.Y.Z | `v1.2.3` |

---

*Last updated: 2026-01-31*
