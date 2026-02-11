#!/usr/bin/env bats
#
# Example Addon Tests - ingress-nginx
# Tests for the ingress-nginx addon installation
#

load '../test_helper/common'

# =============================================================================
# Setup
# =============================================================================

setup_file() {
  export PROJECT_ROOT
  PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  export ADDON_DIR="$PROJECT_ROOT/eks/addons/ingress-nginx"
  export INSTALL_SCRIPT="$ADDON_DIR/install.sh"
  export UNINSTALL_SCRIPT="$ADDON_DIR/uninstall.sh"
}

# =============================================================================
# Script Structure Tests
# =============================================================================

@test "ingress-nginx: install.sh exists" {
  [ -f "$INSTALL_SCRIPT" ]
}

@test "ingress-nginx: install.sh is executable" {
  [ -x "$INSTALL_SCRIPT" ]
}

@test "ingress-nginx: uninstall.sh exists" {
  [ -f "$UNINSTALL_SCRIPT" ]
}

@test "ingress-nginx: README.md exists" {
  [ -f "$ADDON_DIR/README.md" ]
}

@test "ingress-nginx: values directory exists" {
  [ -d "$ADDON_DIR/values" ] || skip "No values directory"
}

# =============================================================================
# CLI Compliance Tests
# =============================================================================

@test "ingress-nginx: install.sh --help works" {
  run "$INSTALL_SCRIPT" --help
  assert_success
  assert_output --partial "Usage:"
}

@test "ingress-nginx: install.sh --version works" {
  run "$INSTALL_SCRIPT" --version
  assert_success
}

@test "ingress-nginx: install.sh requires --cluster" {
  run "$INSTALL_SCRIPT"
  assert_failure
  assert_output --partial "cluster" || assert_output --partial "required"
}

@test "ingress-nginx: install.sh --dry-run is supported" {
  run grep -- "--dry-run" "$INSTALL_SCRIPT"
  assert_success
}

# =============================================================================
# Help Output Tests
# =============================================================================

@test "ingress-nginx: help shows --cluster option" {
  run "$INSTALL_SCRIPT" --help
  assert_output --partial "--cluster"
}

@test "ingress-nginx: help shows --namespace option" {
  run "$INSTALL_SCRIPT" --help
  assert_output --partial "--namespace"
}

@test "ingress-nginx: help shows --values option" {
  run "$INSTALL_SCRIPT" --help
  assert_output --partial "--values" || skip "No --values option"
}

# =============================================================================
# Code Quality Tests
# =============================================================================

@test "ingress-nginx: install.sh uses set -e" {
  run grep -E "^set -e|^set -.*e" "$INSTALL_SCRIPT"
  assert_success
}

@test "ingress-nginx: install.sh uses pipefail" {
  run grep "pipefail" "$INSTALL_SCRIPT"
  assert_success
}

@test "ingress-nginx: install.sh passes shellcheck" {
  skip_if_missing "shellcheck"
  run shellcheck "$INSTALL_SCRIPT"
  assert_success
}

# =============================================================================
# Values Files Tests
# =============================================================================

@test "ingress-nginx: default values file exists" {
  local values_file="$ADDON_DIR/values/default.yaml"
  [ -f "$values_file" ] || skip "No default.yaml"
}

@test "ingress-nginx: values files are valid YAML" {
  skip_if_missing "yamllint"
  
  for file in "$ADDON_DIR"/values/*.yaml; do
    [ -f "$file" ] || continue
    run yamllint -d relaxed "$file"
    assert_success
  done
}

# =============================================================================
# Integration Tests (require cluster)
# =============================================================================

@test "ingress-nginx: dry-run succeeds on cluster" {
  skip_if_no_cluster
  
  run "$INSTALL_SCRIPT" \
    --cluster "$(kubectl config current-context)" \
    --dry-run
  
  assert_success
}

# Note: Actual installation tests should be in a separate integration test file
# that's only run in CI with a real cluster
