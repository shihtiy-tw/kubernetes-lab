# Common test utilities for kubernetes-lab
# Source this in your BATS tests: load 'test_helper/common'

# =============================================================================
# Setup
# =============================================================================

# Project root directory
export PROJECT_ROOT
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load BATS helpers if available
if [[ -d "${PROJECT_ROOT}/tests/test_helper/bats-support" ]]; then
  load 'bats-support/load'
fi

if [[ -d "${PROJECT_ROOT}/tests/test_helper/bats-assert" ]]; then
  load 'bats-assert/load'
fi

# =============================================================================
# Helper Functions
# =============================================================================

# Check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Skip test if command is missing
skip_if_missing() {
  local cmd="$1"
  if ! command_exists "$cmd"; then
    skip "$cmd is not installed"
  fi
}

# Skip test if no cluster is available
skip_if_no_cluster() {
  if ! kubectl cluster-info &>/dev/null; then
    skip "No Kubernetes cluster available"
  fi
}

# Skip test if not on EKS
skip_if_not_eks() {
  local context
  context=$(kubectl config current-context 2>/dev/null || echo "")
  if [[ "$context" != *"eks"* ]]; then
    skip "Not connected to an EKS cluster"
  fi
}

# =============================================================================
# Script Verification
# =============================================================================

# Check if script is executable
assert_executable() {
  local script="$1"
  assert [ -x "$script" ]
}

# Check if script has shebang
assert_has_shebang() {
  local script="$1"
  local first_line
  first_line=$(head -1 "$script")
  [[ "$first_line" == "#!/"* ]]
}

# Check if script has --help
assert_has_help() {
  local script="$1"
  run "$script" --help
  assert_success
  assert_output --partial "Usage:"
}

# Check if script has --version
assert_has_version() {
  local script="$1"
  run "$script" --version
  assert_success
  assert_output --partial "version"
}

# Check if script has --dry-run
assert_has_dry_run() {
  local script="$1"
  grep -q -- "--dry-run" "$script"
}

# =============================================================================
# File System Helpers
# =============================================================================

# Create temporary directory for test
create_temp_dir() {
  mktemp -d -t bats-test.XXXXXX
}

# Get all shell scripts in directory
find_shell_scripts() {
  local dir="${1:-$PROJECT_ROOT}"
  find "$dir" -name "*.sh" -type f 2>/dev/null
}

# Get all addon install scripts
find_addon_scripts() {
  find "$PROJECT_ROOT/eks/addons" -name "install.sh" -type f 2>/dev/null
}

# Get all scenario deploy scripts
find_scenario_scripts() {
  find "$PROJECT_ROOT/eks/scenarios" -name "deploy.sh" -type f 2>/dev/null
}

# =============================================================================
# Kubernetes Helpers
# =============================================================================

# Wait for deployment to be ready
wait_for_deployment() {
  local name="$1"
  local namespace="${2:-default}"
  local timeout="${3:-120s}"
  
  kubectl rollout status deployment/"$name" -n "$namespace" --timeout="$timeout"
}

# Check if namespace exists
namespace_exists() {
  local namespace="$1"
  kubectl get namespace "$namespace" &>/dev/null
}

# Check if resource exists
resource_exists() {
  local kind="$1"
  local name="$2"
  local namespace="${3:-default}"
  
  kubectl get "$kind" "$name" -n "$namespace" &>/dev/null
}

# =============================================================================
# Helm Helpers
# =============================================================================

# Check if Helm release exists
helm_release_exists() {
  local release="$1"
  local namespace="${2:-default}"
  
  helm status "$release" -n "$namespace" &>/dev/null
}

# Get Helm release status
helm_release_status() {
  local release="$1"
  local namespace="${2:-default}"
  
  helm status "$release" -n "$namespace" -o json | jq -r '.info.status'
}

# =============================================================================
# Output Helpers
# =============================================================================

# Debug helper - prints to console during tests
debug() {
  echo "# DEBUG: $*" >&3
}

# Print all output for debugging
dump_output() {
  echo "# OUTPUT: $output" >&3
  echo "# STATUS: $status" >&3
}
