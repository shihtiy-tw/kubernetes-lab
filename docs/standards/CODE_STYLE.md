# Code Style Guide

This document defines the coding standards for all code in kubernetes-lab.

## Table of Contents

- [Shell Scripts (Bash)](#shell-scripts-bash)
- [YAML Files](#yaml-files)
- [Terraform](#terraform)
- [General Principles](#general-principles)

---

## Shell Scripts (Bash)

### File Headers

Every shell script must start with:

```bash
#!/usr/bin/env bash
#
# script-name.sh - Brief description of what the script does
#
# Usage:
#   ./script-name.sh --option value
#   ./script-name.sh --help
#
# Examples:
#   ./script-name.sh --install
#   ./script-name.sh --dry-run
#

set -euo pipefail
```

### CLI 12-Factor Compliance

All scripts **MUST** implement:

| Requirement | Implementation |
|-------------|----------------|
| `--help` | Display usage information |
| `--version` | Show script version |
| Flags only | No positional arguments |
| `--dry-run` | Preview without execution |
| Exit codes | 0 = success, 1 = error |
| Stdout/stderr | Proper stream separation |

### Naming Conventions

```bash
# Variables: UPPER_SNAKE_CASE for environment/exports
export CLUSTER_NAME="my-cluster"
export AWS_REGION="us-west-2"

# Local variables: lower_snake_case
local cluster_name="my-cluster"
local node_count=3

# Constants: Prefix with readonly
readonly DEFAULT_K8S_VERSION="1.28"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions: lower_snake_case
function create_cluster() {
    # ...
}

# Boolean functions: use is_, has_, can_ prefix
function is_cluster_ready() {
    # ...
}
```

### Error Handling

```bash
# Use trap for cleanup
trap cleanup EXIT

function cleanup() {
    local exit_code=$?
    # Cleanup logic here
    exit "$exit_code"
}

# Log errors to stderr
function log_error() {
    echo "[ERROR] $*" >&2
}

# Validate required variables
: "${CLUSTER_NAME:?Error: CLUSTER_NAME is required}"
```

### Functions

```bash
# Document all functions
#######################################
# Creates an EKS cluster with the specified configuration.
#
# Globals:
#   CLUSTER_NAME - Name of the cluster
#   AWS_REGION - AWS region
#
# Arguments:
#   $1 - Node count (optional, default: 2)
#
# Outputs:
#   Writes cluster ARN to stdout
#
# Returns:
#   0 on success, 1 on failure
#######################################
function create_cluster() {
    local node_count="${1:-2}"
    # Implementation
}
```

---

## YAML Files

### Kubernetes Manifests

```yaml
# Always include apiVersion, kind, metadata
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: default
  labels:
    app.kubernetes.io/name: my-app
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: my-system
    app.kubernetes.io/managed-by: helm
```

### Formatting Rules

1. **Indentation**: 2 spaces, no tabs
2. **Line length**: Max 120 characters
3. **Quotes**: Use when containing special characters
4. **Comments**: Start with `#` followed by space
5. **Lists**: Use `-` for arrays

```yaml
# Good
containers:
  - name: app
    image: nginx:1.25
    ports:
      - containerPort: 80

# Bad - inconsistent formatting
containers:
- name: app
  image: "nginx:1.25"
  ports:
  - containerPort: 80
```

### Helm Values

```yaml
# Use descriptive section comments
# -- Image configuration
image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent

# -- Resource limits and requests
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

---

## Terraform

### File Structure

```
module/
├── main.tf          # Primary resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider requirements
├── locals.tf        # Local values
├── data.tf          # Data sources
└── README.md        # Documentation
```

### Naming Conventions

```hcl
# Resources: provider_type_name
resource "aws_eks_cluster" "main" {}
resource "aws_security_group" "cluster" {}

# Variables: descriptive, snake_case
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

# Locals: computed values
locals {
  cluster_oidc_issuer = trimprefix(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://")
}

# Outputs: resource_attribute format
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}
```

### Variable Definitions

```hcl
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  
  validation {
    condition     = length(var.cluster_name) <= 40
    error_message = "Cluster name must be 40 characters or less."
  }
}

variable "node_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}
```

---

## General Principles

### 1. Readability First

- Code is read more often than written
- Prefer clarity over cleverness
- Use meaningful names
- Add comments for non-obvious logic

### 2. Fail Fast

- Validate inputs early
- Check prerequisites before execution
- Provide clear error messages
- Exit with appropriate codes

### 3. Idempotency

- Scripts should be safe to run multiple times
- Check state before making changes
- Implement proper cleanup

### 4. Security

- Never hardcode credentials
- Use environment variables or secrets managers
- Validate external inputs
- Follow least privilege principle

### 5. Documentation

- Document public APIs
- Include usage examples
- Keep docs updated with code
- Use consistent formatting

---

## Tooling

### Required Tools

| Tool | Purpose | Config File |
|------|---------|-------------|
| ShellCheck | Shell linting | `.shellcheckrc` |
| shfmt | Shell formatting | `.editorconfig` |
| yamllint | YAML linting | `.yamllint` |
| markdownlint | Markdown linting | `.markdownlint.json` |
| hadolint | Dockerfile linting | `.hadolint.yaml` |
| terraform fmt | Terraform formatting | - |
| tflint | Terraform linting | `.tflint.hcl` |

### Pre-commit Hooks

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run on all files
pre-commit run --all-files
```

---

## Enforcement

- Pre-commit hooks prevent non-compliant commits
- CI pipeline validates all PRs
- Code review checks for style compliance
- Automated fixes where possible

---

*Last updated: 2026-01-31*
