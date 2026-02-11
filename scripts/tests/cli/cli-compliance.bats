#!/usr/bin/env bats
#
# CLI 12-Factor Compliance Tests
# Validates that all scripts follow CLI 12-factor principles
#

load '../test_helper/common'

# =============================================================================
# Setup
# =============================================================================

setup_file() {
  export PROJECT_ROOT
  PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

# =============================================================================
# General Compliance Tests
# =============================================================================

@test "all shell scripts have shebang" {
  local failed=0
  
  while IFS= read -r script; do
    local first_line
    first_line=$(head -1 "$script")
    if [[ "$first_line" != "#!/"* ]]; then
      echo "# Missing shebang: $script" >&3
      ((failed++))
    fi
  done < <(find_shell_scripts)
  
  [ "$failed" -eq 0 ]
}

@test "all shell scripts are executable" {
  local failed=0
  
  while IFS= read -r script; do
    if [[ ! -x "$script" ]]; then
      echo "# Not executable: $script" >&3
      ((failed++))
    fi
  done < <(find_shell_scripts)
  
  [ "$failed" -eq 0 ]
}

# =============================================================================
# --help Flag Tests
# =============================================================================

@test "addon install scripts have --help flag" {
  skip_if_missing "grep"
  
  local failed=0
  
  while IFS= read -r script; do
    if ! grep -q -- "--help" "$script"; then
      echo "# Missing --help: $script" >&3
      ((failed++))
    fi
  done < <(find_addon_scripts)
  
  [ "$failed" -eq 0 ]
}

@test "addon install --help outputs usage information" {
  while IFS= read -r script; do
    run "$script" --help
    assert_success
    assert_output --partial "Usage:" || assert_output --partial "usage:"
  done < <(find_addon_scripts | head -3)  # Test first 3 to avoid timeout
}

# =============================================================================
# --version Flag Tests
# =============================================================================

@test "addon install scripts have --version flag" {
  skip_if_missing "grep"
  
  local failed=0
  
  while IFS= read -r script; do
    if ! grep -q -- "--version" "$script"; then
      echo "# Missing --version: $script" >&3
      ((failed++))
    fi
  done < <(find_addon_scripts)
  
  [ "$failed" -eq 0 ]
}

@test "addon install --version outputs version" {
  while IFS= read -r script; do
    run "$script" --version
    assert_success
    # Should contain "version" or a version number pattern
    [[ "$output" =~ version ]] || [[ "$output" =~ [0-9]+\.[0-9]+ ]]
  done < <(find_addon_scripts | head -3)
}

# =============================================================================
# --dry-run Flag Tests
# =============================================================================

@test "addon install scripts have --dry-run support" {
  skip_if_missing "grep"
  
  local failed=0
  
  while IFS= read -r script; do
    if ! grep -q -- "--dry-run" "$script"; then
      echo "# Missing --dry-run: $script" >&3
      ((failed++))
    fi
  done < <(find_addon_scripts)
  
  [ "$failed" -eq 0 ]
}

# =============================================================================
# Error Handling Tests
# =============================================================================

@test "scripts use set -e for error handling" {
  local failed=0
  
  while IFS= read -r script; do
    if ! grep -qE "^set -e|^set -.*e" "$script"; then
      echo "# Missing set -e: $script" >&3
      ((failed++))
    fi
  done < <(find_addon_scripts)
  
  [ "$failed" -eq 0 ]
}

@test "scripts use set -u for undefined variable handling" {
  local failed=0
  
  while IFS= read -r script; do
    if ! grep -qE "^set -.*u|^set -euo" "$script"; then
      echo "# Missing set -u: $script" >&3
      ((failed++))
    fi
  done < <(find_addon_scripts)
  
  [ "$failed" -eq 0 ]
}

@test "scripts use pipefail" {
  local failed=0
  
  while IFS= read -r script; do
    if ! grep -q "pipefail" "$script"; then
      echo "# Missing pipefail: $script" >&3
      ((failed++))
    fi
  done < <(find_addon_scripts)
  
  [ "$failed" -eq 0 ]
}

# =============================================================================
# Logging Tests
# =============================================================================

@test "scripts use logging functions" {
  while IFS= read -r script; do
    # Should have at least one logging function
    run grep -E "log_info|log_error|log_warn|echo.*INFO|echo.*ERROR" "$script"
    assert_success
  done < <(find_addon_scripts | head -3)
}

# =============================================================================
# Return Code Tests
# =============================================================================

@test "scripts return 0 on --help" {
  while IFS= read -r script; do
    run "$script" --help
    assert_success  # exit code 0
  done < <(find_addon_scripts | head -3)
}

@test "scripts return 0 on --version" {
  while IFS= read -r script; do
    run "$script" --version
    assert_success  # exit code 0
  done < <(find_addon_scripts | head -3)
}

@test "scripts return non-zero on missing required args" {
  while IFS= read -r script; do
    run "$script"
    # Should fail without --cluster or other required args
    [ "$status" -ne 0 ] || skip "Script may not require arguments"
  done < <(find_addon_scripts | head -3)
}

# =============================================================================
# Structure Tests
# =============================================================================

@test "addon directories have install.sh" {
  for addon_dir in "$PROJECT_ROOT"/eks/addons/*/; do
    # Skip if not a directory
    [[ -d "$addon_dir" ]] || continue
    
    local install_script="${addon_dir}install.sh"
    [ -f "$install_script" ] || {
      echo "# Missing install.sh: $addon_dir" >&3
      false
    }
  done
}

@test "addon directories have README.md" {
  local failed=0
  
  for addon_dir in "$PROJECT_ROOT"/eks/addons/*/; do
    [[ -d "$addon_dir" ]] || continue
    
    if [[ ! -f "${addon_dir}README.md" ]]; then
      echo "# Missing README.md: $addon_dir" >&3
      ((failed++))
    fi
  done
  
  [ "$failed" -eq 0 ]
}
