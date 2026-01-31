# Error Handling Standards

Guidelines for consistent error handling across kubernetes-lab scripts and configurations.

## Table of Contents

- [Bash Scripts](#bash-scripts)
- [Exit Codes](#exit-codes)
- [Error Messages](#error-messages)
- [Logging](#logging)
- [Kubernetes Error Handling](#kubernetes-error-handling)
- [Recovery Strategies](#recovery-strategies)

---

## Bash Scripts

### Required Settings

Every script must start with strict mode:

```bash
#!/usr/bin/env bash
set -euo pipefail

# -e: Exit immediately on command failure
# -u: Treat unset variables as errors
# -o pipefail: Pipeline returns rightmost non-zero exit code
```

### Trap for Cleanup

Always use trap for cleanup operations:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Cleanup function
cleanup() {
    local exit_code=$?
    
    # Remove temporary files
    [[ -f "${TEMP_FILE:-}" ]] && rm -f "$TEMP_FILE"
    
    # Reset terminal if needed
    tput sgr0 2>/dev/null || true
    
    # Log exit
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script exited with code: $exit_code"
    fi
    
    exit "$exit_code"
}

# Register cleanup
trap cleanup EXIT
trap 'trap - EXIT; cleanup; exit 130' INT
trap 'trap - EXIT; cleanup; exit 143' TERM
```

### Error Functions

```bash
# Standard log functions
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Fatal error - exits script
die() {
    log_error "$*"
    exit 1
}

# Check command success
check_command() {
    if ! "$@"; then
        die "Command failed: $*"
    fi
}
```

### Validation Patterns

```bash
# Validate required variables
validate_required() {
    local var_name="$1"
    local var_value="${!var_name:-}"
    
    if [[ -z "$var_value" ]]; then
        die "Required variable not set: $var_name"
    fi
}

# Usage
validate_required CLUSTER_NAME
validate_required AWS_REGION

# Validate required tools
validate_tools() {
    local missing_tools=()
    
    for tool in "$@"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        die "Missing required tools: ${missing_tools[*]}"
    fi
}

# Usage
validate_tools kubectl helm aws
```

---

## Exit Codes

Use consistent exit codes across all scripts:

| Code | Meaning | When to Use |
|------|---------|-------------|
| 0 | Success | Script completed successfully |
| 1 | General error | Unspecified/generic error |
| 2 | Usage error | Invalid arguments or usage |
| 3 | Prerequisites failed | Missing tools or permissions |
| 4 | Resource not found | Cluster, addon not found |
| 5 | Timeout | Operation timed out |
| 10 | AWS error | AWS API call failed |
| 11 | Kubernetes error | K8s API call failed |
| 130 | Interrupted (Ctrl+C) | User cancelled |
| 143 | Terminated (SIGTERM) | Process was terminated |

### Implementation

```bash
# Define exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_USAGE=2
readonly EXIT_PREREQ=3
readonly EXIT_NOT_FOUND=4
readonly EXIT_TIMEOUT=5
readonly EXIT_AWS_ERROR=10
readonly EXIT_K8S_ERROR=11

# Usage
if ! kubectl get cluster "$CLUSTER_NAME" &>/dev/null; then
    log_error "Cluster not found: $CLUSTER_NAME"
    exit $EXIT_NOT_FOUND
fi
```

---

## Error Messages

### Format

```bash
# Include context in error messages
# Format: [ERROR] <what failed>: <why/details>

# Good
log_error "Failed to create cluster 'my-cluster': insufficient permissions"
log_error "Cannot connect to Kubernetes API: timeout after 30 seconds"
log_error "Invalid argument '--foo': expected integer, got 'bar'"

# Bad - too vague
log_error "Error occurred"
log_error "Failed"
log_error "Invalid input"
```

### Include Actionable Information

```bash
# Good - tells user what to do
log_error "AWS credentials not configured. Run 'aws configure' or set AWS_ACCESS_KEY_ID"
log_error "kubectl not found. Install from: https://kubernetes.io/docs/tasks/tools/"
log_error "Cluster 'my-cluster' not found in region 'us-west-2'. Check cluster name and region."

# Bad - no guidance
log_error "Authentication failed"
log_error "Command not found"
log_error "Cluster not found"
```

---

## Logging

### Log Levels

```bash
# Verbose logging with levels
LOG_LEVEL="${LOG_LEVEL:-INFO}"

log() {
    local level="$1"
    shift
    
    case "$LOG_LEVEL" in
        DEBUG) true ;;
        INFO)  [[ "$level" == "DEBUG" ]] && return ;;
        WARN)  [[ "$level" =~ ^(DEBUG|INFO)$ ]] && return ;;
        ERROR) [[ "$level" =~ ^(DEBUG|INFO|WARN)$ ]] && return ;;
    esac
    
    local color=""
    case "$level" in
        DEBUG) color="\033[0;37m" ;;
        INFO)  color="\033[0;34m" ;;
        WARN)  color="\033[1;33m" ;;
        ERROR) color="\033[0;31m" ;;
    esac
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${color}[$timestamp] [$level]${NC} $*" >&2
}

log_debug() { log DEBUG "$@"; }
log_info()  { log INFO "$@"; }
log_warn()  { log WARN "$@"; }
log_error() { log ERROR "$@"; }
```

### Output Separation

```bash
# Stdout: Primary output, machine-readable
# Stderr: Logs, errors, progress

# Good
echo "$CLUSTER_ARN"           # to stdout - can be captured
log_info "Creating cluster"   # to stderr - visible but not captured

# Capture output example
cluster_arn=$(./create-cluster.sh --name my-cluster)
echo "Cluster ARN: $cluster_arn"
```

---

## Kubernetes Error Handling

### kubectl Commands

```bash
# Check kubectl connectivity
check_k8s_connection() {
    if ! kubectl cluster-info &>/dev/null; then
        die "Cannot connect to Kubernetes API. Check KUBECONFIG and cluster status."
    fi
}

# Wait for resource with timeout
wait_for_resource() {
    local resource="$1"
    local condition="$2"
    local timeout="${3:-300}"
    
    log_info "Waiting for $resource to be $condition (timeout: ${timeout}s)"
    
    if ! kubectl wait "$resource" --for="$condition" --timeout="${timeout}s"; then
        log_error "Timeout waiting for $resource"
        kubectl describe "$resource" >&2
        return $EXIT_TIMEOUT
    fi
}

# Usage
wait_for_resource "deployment/nginx" "condition=available" 120
```

### Helm Commands

```bash
# Check Helm release status
check_helm_release() {
    local release="$1"
    local namespace="$2"
    
    if ! helm status "$release" -n "$namespace" &>/dev/null; then
        log_error "Helm release not found: $release in namespace $namespace"
        return $EXIT_NOT_FOUND
    fi
}

# Install with error handling
helm_install() {
    local release="$1"
    local chart="$2"
    local namespace="$3"
    shift 3
    
    log_info "Installing Helm release: $release"
    
    if ! helm upgrade --install "$release" "$chart" \
         --namespace "$namespace" \
         --create-namespace \
         --wait \
         --timeout 10m \
         "$@"; then
        log_error "Failed to install Helm release: $release"
        helm history "$release" -n "$namespace" >&2 || true
        return $EXIT_K8S_ERROR
    fi
    
    log_info "Successfully installed: $release"
}
```

---

## Recovery Strategies

### Retries with Exponential Backoff

```bash
# Retry with exponential backoff
retry() {
    local max_attempts="${MAX_RETRIES:-5}"
    local delay=1
    local attempt=1
    
    while true; do
        if "$@"; then
            return 0
        fi
        
        if [[ $attempt -ge $max_attempts ]]; then
            log_error "Failed after $max_attempts attempts: $*"
            return 1
        fi
        
        log_warn "Attempt $attempt/$max_attempts failed, retrying in ${delay}s..."
        sleep "$delay"
        
        ((attempt++))
        ((delay *= 2))  # Exponential backoff
        
        # Cap max delay at 60 seconds
        [[ $delay -gt 60 ]] && delay=60
    done
}

# Usage
retry kubectl apply -f manifest.yaml
retry aws eks describe-cluster --name my-cluster
```

### Graceful Degradation

```bash
# Optional features that shouldn't fail the script
install_optional_addon() {
    local addon="$1"
    
    if ! ./install-addon.sh "$addon"; then
        log_warn "Optional addon failed to install: $addon"
        log_warn "Continuing without $addon"
        return 0  # Don't fail the script
    fi
}

# Required with fallback
install_with_fallback() {
    local primary="$1"
    local fallback="$2"
    
    if ./install-addon.sh "$primary"; then
        return 0
    fi
    
    log_warn "Primary installation failed, trying fallback..."
    
    if ./install-addon.sh "$fallback"; then
        return 0
    fi
    
    die "Both primary and fallback installations failed"
}
```

---

## Checklist

When writing error handling code, ensure:

- [ ] Script starts with `set -euo pipefail`
- [ ] Cleanup trap is registered
- [ ] Required variables are validated
- [ ] Required tools are checked
- [ ] Error messages include context
- [ ] Error messages include remediation steps
- [ ] Exit codes are consistent
- [ ] Logs go to stderr, output to stdout
- [ ] Retries are implemented for transient failures
- [ ] Timeouts are defined for long operations

---

*Last updated: 2026-01-31*
