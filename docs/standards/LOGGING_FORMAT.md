# Logging Format Specification

Standard logging format for all kubernetes-lab scripts.

## Log Format

### Standard Log Entry

```
[TIMESTAMP] [LEVEL] [COMPONENT] MESSAGE
```

Example:
```
[2026-01-31 14:30:45] [INFO] [ingress-nginx] Installing addon version 4.8.0
[2026-01-31 14:30:46] [DEBUG] [ingress-nginx] Running: helm upgrade --install...
[2026-01-31 14:31:02] [INFO] [ingress-nginx] Installation complete
```

### Simplified Format (Default)

For interactive use, we use a simplified format:

```
[LEVEL] MESSAGE
```

Example:
```
[INFO] Installing ingress-nginx addon
[WARN] Using default values, no custom values file provided
[ERROR] Failed to connect to Kubernetes API
```

## Log Levels

| Level | Color | Usage |
|-------|-------|-------|
| DEBUG | Gray | Detailed debugging information |
| INFO | Blue | Normal operational messages |
| WARN | Yellow | Warning conditions |
| ERROR | Red | Error conditions |

## Implementation

### Color Codes

```bash
# ANSI Color codes
readonly LOG_COLOR_DEBUG='\033[0;37m'    # Gray
readonly LOG_COLOR_INFO='\033[0;34m'     # Blue
readonly LOG_COLOR_WARN='\033[1;33m'     # Yellow
readonly LOG_COLOR_ERROR='\033[0;31m'    # Red
readonly LOG_COLOR_SUCCESS='\033[0;32m'  # Green
readonly LOG_COLOR_RESET='\033[0m'       # Reset
```

### Logging Functions

```bash
# Detect color support
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "1" ]]; then
    USE_COLOR=true
else
    USE_COLOR=false
fi

# Log with timestamp (for DEBUG mode)
log_with_timestamp() {
    local level="$1"
    local color="$2"
    shift 2
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$USE_COLOR" == "true" ]]; then
        echo -e "${color}[${timestamp}] [${level}]${LOG_COLOR_RESET} $*" >&2
    else
        echo "[${timestamp}] [${level}] $*" >&2
    fi
}

# Simple log (default)
log() {
    local level="$1"
    local color="$2"
    shift 2
    
    if [[ "$USE_COLOR" == "true" ]]; then
        echo -e "${color}[${level}]${LOG_COLOR_RESET} $*" >&2
    else
        echo "[${level}] $*" >&2
    fi
}

# Level-specific functions
log_debug() {
    [[ "${LOG_LEVEL:-INFO}" == "DEBUG" ]] || return 0
    log "DEBUG" "$LOG_COLOR_DEBUG" "$@"
}

log_info() {
    log "INFO" "$LOG_COLOR_INFO" "$@"
}

log_warn() {
    log "WARN" "$LOG_COLOR_WARN" "$@"
}

log_error() {
    log "ERROR" "$LOG_COLOR_ERROR" "$@"
}

log_success() {
    log "OK" "$LOG_COLOR_SUCCESS" "$@"
}
```

## Log Level Control

### Environment Variable

```bash
# Set log level via environment variable
export LOG_LEVEL=DEBUG  # Show all logs
export LOG_LEVEL=INFO   # Default, show INFO and above
export LOG_LEVEL=WARN   # Show WARN and ERROR only
export LOG_LEVEL=ERROR  # Show ERROR only
```

### Implementation

```bash
# Check if log level should be shown
should_log() {
    local level="$1"
    local current_level="${LOG_LEVEL:-INFO}"
    
    case "$current_level" in
        DEBUG) return 0 ;;
        INFO)  [[ "$level" != "DEBUG" ]] ;;
        WARN)  [[ "$level" =~ ^(WARN|ERROR)$ ]] ;;
        ERROR) [[ "$level" == "ERROR" ]] ;;
        *) return 0 ;;
    esac
}
```

## Output Streams

### Rules

| Type | Stream | Example |
|------|--------|---------|
| Primary output | stdout | Cluster ARN, resource names |
| Logs | stderr | Progress, debug, errors |
| Errors | stderr | All error messages |

### Implementation

```bash
# Output to stdout (can be captured)
output() {
    echo "$@"
}

# All logs go to stderr
log_info "Starting installation..."  # -> stderr
log_error "Failed to connect"         # -> stderr

# Primary output to stdout
output "$CLUSTER_ARN"                  # -> stdout

# Usage
cluster_arn=$(./create-cluster.sh --name my-cluster)
# logs visible on terminal, only ARN captured
```

## Special Log Patterns

### Section Headers

```bash
log_section() {
    local title="$1"
    echo "" >&2
    echo -e "${LOG_COLOR_INFO}=== ${title} ===${LOG_COLOR_RESET}" >&2
    echo "" >&2
}

# Usage
log_section "Installing Prerequisites"
log_info "Checking kubectl..."
log_info "Checking helm..."
```

### Progress Indicators

```bash
# Step indicator
log_step() {
    local current="$1"
    local total="$2"
    local message="$3"
    
    log "STEP" "$LOG_COLOR_INFO" "[$current/$total] $message"
}

# Usage
log_step 1 5 "Creating VPC..."
log_step 2 5 "Creating EKS cluster..."
```

### Dry Run Prefix

```bash
# Indicate dry run actions
log_dry_run() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "DRY" "$LOG_COLOR_WARN" "Would execute: $*"
    fi
}

# Usage
if [[ "$DRY_RUN" == "true" ]]; then
    log_dry_run "kubectl apply -f manifest.yaml"
else
    kubectl apply -f manifest.yaml
fi
```

## Best Practices

### Do

- ✅ Log meaningful context
- ✅ Include relevant identifiers (cluster name, addon name)
- ✅ Log at appropriate level
- ✅ Use stderr for all logs
- ✅ Support NO_COLOR environment variable
- ✅ Make logs grep-friendly

### Don't

- ❌ Log sensitive information (secrets, passwords)
- ❌ Use print statements without log level
- ❌ Output logs to stdout
- ❌ Use colors without checking terminal capability
- ❌ Log excessively at INFO level

## Examples

### Good Logging

```bash
log_info "Creating EKS cluster: $CLUSTER_NAME in region $AWS_REGION"
log_debug "Using Kubernetes version: $K8S_VERSION"
log_debug "Node instance types: ${NODE_TYPES[*]}"

log_info "Waiting for cluster to be ready..."
log_warn "Cluster creation may take 10-15 minutes"

if ! wait_for_cluster "$CLUSTER_NAME"; then
    log_error "Cluster creation failed: timeout after 20 minutes"
    log_error "Check AWS console for details: https://..."
    exit 1
fi

log_success "Cluster created successfully"
log_info "Cluster endpoint: $CLUSTER_ENDPOINT"
```

### Bad Logging

```bash
# Too vague
echo "Starting..."
echo "Done"

# No context
log_error "Failed"

# Sensitive data
log_info "Using AWS secret: $AWS_SECRET_KEY"

# Wrong stream
echo "Error occurred"  # should use log_error and go to stderr
```

---

*Last updated: 2026-01-31*
