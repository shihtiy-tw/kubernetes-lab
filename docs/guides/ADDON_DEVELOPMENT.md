# Addon Development Guide

Guide for creating new addons in kubernetes-lab.

## Prerequisites

- Understanding of Helm charts
- Familiarity with Kubernetes concepts
- Bash scripting knowledge

## Quick Start

1. Copy the addon template:
   ```bash
   cp -r templates/addon-template eks/addons/my-addon
   ```

2. Customize the files:
   - Update `install.sh` with addon-specific logic
   - Add Helm values in `values/`
   - Write documentation in `README.md`

3. Test the addon:
   ```bash
   ./eks/addons/my-addon/install.sh --dry-run
   ```

## Addon Structure

```
eks/addons/<addon-name>/
├── install.sh            # Main installer
├── uninstall.sh          # Cleanup script
├── values/
│   ├── default.yaml      # Default Helm values
│   └── production.yaml   # Production overrides
├── manifests/            # Optional raw manifests
├── README.md             # Documentation
└── tests/
    └── install.bats      # BATS tests
```

## Script Template

### install.sh

```bash
#!/usr/bin/env bash
#
# install.sh - Install <addon-name>
#
# Usage:
#   ./install.sh --cluster CLUSTER [OPTIONS]
#

set -euo pipefail

# =============================================================================
# Constants
# =============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"
readonly ADDON_NAME="<addon-name>"

# Defaults
readonly DEFAULT_NAMESPACE="<addon-name>"
readonly DEFAULT_RELEASE_NAME="<addon-name>"
readonly HELM_CHART="<repo>/<chart>"
readonly CHART_VERSION="1.0.0"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# =============================================================================
# Variables
# =============================================================================

CLUSTER=""
NAMESPACE="$DEFAULT_NAMESPACE"
RELEASE_NAME="$DEFAULT_RELEASE_NAME"
VALUES_FILE=""
DRY_RUN=false
VERBOSE=false

# =============================================================================
# Functions
# =============================================================================

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }

show_help() {
  cat << EOF
Usage: $SCRIPT_NAME --cluster CLUSTER [OPTIONS]

Install $ADDON_NAME on a Kubernetes cluster.

Required:
  --cluster NAME        Target cluster name

Options:
  --namespace NS        Namespace (default: $DEFAULT_NAMESPACE)
  --release NAME        Helm release name (default: $DEFAULT_RELEASE_NAME)
  --values FILE         Custom values file
  --dry-run             Show what would be done
  --verbose             Enable verbose output
  --help                Show this help
  --version             Show version

Examples:
  $SCRIPT_NAME --cluster my-eks
  $SCRIPT_NAME --cluster my-eks --values values/production.yaml
  $SCRIPT_NAME --cluster my-eks --dry-run

EOF
}

show_version() {
  echo "$ADDON_NAME installer version $VERSION"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --cluster) CLUSTER="$2"; shift 2 ;;
      --namespace) NAMESPACE="$2"; shift 2 ;;
      --release) RELEASE_NAME="$2"; shift 2 ;;
      --values) VALUES_FILE="$2"; shift 2 ;;
      --dry-run) DRY_RUN=true; shift ;;
      --verbose) VERBOSE=true; shift ;;
      --help) show_help; exit 0 ;;
      --version) show_version; exit 0 ;;
      *) log_error "Unknown option: $1"; exit 1 ;;
    esac
  done
}

validate_inputs() {
  if [[ -z "$CLUSTER" ]]; then
    log_error "Missing required: --cluster"
    exit 1
  fi
}

check_prerequisites() {
  local missing=()
  
  for cmd in kubectl helm aws; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing commands: ${missing[*]}"
    exit 1
  fi
}

install_addon() {
  log_info "Installing $ADDON_NAME..."
  
  # Build helm command
  local helm_cmd="helm upgrade --install $RELEASE_NAME $HELM_CHART"
  helm_cmd+=" --namespace $NAMESPACE --create-namespace"
  helm_cmd+=" --version $CHART_VERSION"
  
  if [[ -n "$VALUES_FILE" ]]; then
    helm_cmd+=" -f $VALUES_FILE"
  else
    helm_cmd+=" -f $SCRIPT_DIR/values/default.yaml"
  fi
  
  if [[ "$DRY_RUN" == "true" ]]; then
    helm_cmd+=" --dry-run"
    log_info "[DRY RUN] $helm_cmd"
  fi
  
  if [[ "$VERBOSE" == "true" ]]; then
    log_info "Command: $helm_cmd"
  fi
  
  eval "$helm_cmd"
  
  log_success "$ADDON_NAME installed successfully"
}

# =============================================================================
# Main
# =============================================================================

main() {
  parse_args "$@"
  validate_inputs
  check_prerequisites
  install_addon
}

main "$@"
```

## Values Files

### default.yaml

```yaml
# Default values for <addon-name>
# These are safe for development/testing

replicaCount: 1

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# Enable for development
debug: false
```

### production.yaml

```yaml
# Production values for <addon-name>
# Use with: --values values/production.yaml

replicaCount: 3

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

# High availability
podAntiAffinity: hard

# Production security
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
```

## Testing

### BATS Test Example

```bash
#!/usr/bin/env bats
# tests/install.bats

load '../../../tests/test_helper/bats-support/load'
load '../../../tests/test_helper/bats-assert/load'

@test "install.sh has --help flag" {
  run ./install.sh --help
  assert_success
  assert_output --partial "Usage:"
}

@test "install.sh has --version flag" {
  run ./install.sh --version
  assert_success
  assert_output --partial "version"
}

@test "install.sh requires --cluster" {
  run ./install.sh
  assert_failure
  assert_output --partial "--cluster"
}

@test "install.sh supports --dry-run" {
  run ./install.sh --cluster test --dry-run
  assert_output --partial "[DRY RUN]"
}
```

## README Template

```markdown
# <Addon Name>

Brief description of what this addon does.

## Prerequisites

- Kubernetes cluster
- Helm 3.x
- Required CRDs (if any)

## Installation

\`\`\`bash
./install.sh --cluster my-eks
\`\`\`

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--namespace` | Target namespace | `<addon-name>` |
| `--values` | Custom values file | `values/default.yaml` |

## Values

See [values/default.yaml](values/default.yaml) for all options.

## Uninstallation

\`\`\`bash
./uninstall.sh --cluster my-eks
\`\`\`

## Troubleshooting

### Common Issues

1. **Pod not starting**
   - Check: `kubectl describe pod -n <namespace>`

## See Also

- [Official Documentation](https://...)
```

## Checklist

Before submitting a new addon:

- [ ] `install.sh` has `--help` and `--version`
- [ ] `install.sh` supports `--dry-run`
- [ ] `uninstall.sh` cleans up all resources
- [ ] `values/default.yaml` has sensible defaults
- [ ] `README.md` documents all options
- [ ] BATS tests pass
- [ ] ShellCheck passes
- [ ] Tested on EKS and Kind

---

*Last updated: 2026-01-31*
