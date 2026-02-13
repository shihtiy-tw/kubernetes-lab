#!/bin/bash
# =============================================================================
# test-validate-instances.sh - Test Instance Type Validation Logic
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANAGED_SCRIPT="$ROOT_DIR/eks/utils/setup-managed-nodegroup.sh"

run_test() {
  local test_name="$1"
  local cmd="$2"
  local expected_exit="$3"

  printf "Running test: %s..." "$test_name"

  # Run command, capture output, suppress stdout/stderr for cleanliness unless failed
  output=$(eval "$cmd" 2>&1)
  exit_code=$?

  if [[ $exit_code -eq $expected_exit ]]; then
    printf "${GREEN}PASS${NC}\n"
    return 0
  else
    printf "${RED}FAIL${NC} (Expected %s, got %s)\n" "$expected_exit" "$exit_code"
    echo "Command: $cmd"
    echo "Output:"
    echo "$output"
    return 1
  fi
}

echo "========================================================"
echo "Testing Instance Type Validation"
echo "========================================================"

# Test 1: Valid Instance Type (t3.medium)
# We expect exit code 0 (success) or non-1 (because dry-run might fail on other things like eksctl not found,
# but validation should pass). Ideally validation happens before eksctl.
# Our script runs validation *before* anything else.
# Note: The script calls `eksctl ... --dry-run`. If eksctl is missing or fails, it returns non-zero.
# We care if it fails *specifically* due to validation.
# Actually, our validation script `exit 1` on failure.
# So we expect the script to proceed to dry-run if validation passes.

# Mocking eksctl to avoid actual dry-run errors if possible?
# For now, let's assume if it fails validation, output contains "Error: Instance type".

# 1. Valid Type
if output=$($MANAGED_SCRIPT 1.30 us-east-1 minimal on-demand t3.medium 2>&1); then
   # It might fail later on eksctl, but shouldn't fail validation.
   # Let's check if it did NOT print the error message.
   if [[ "$output" == *"Error: Instance type"* ]]; then
     printf "${RED}FAIL: Valid type t3.medium was rejected.${NC}\n"
   else
     printf "${GREEN}PASS: Valid type t3.medium accepted.${NC}\n"
   fi
else
   # If script failed, check if it was validation error
   if [[ "$output" == *"Error: Instance type"* ]]; then
     printf "${RED}FAIL: Valid type t3.medium was rejected.${NC}\n"
   else
     printf "${GREEN}PASS: Valid type t3.medium accepted (script failed elsewhere).${NC}\n"
   fi
fi

# 2. Invalid Type (r5.large)
if output=$($MANAGED_SCRIPT 1.30 us-east-1 minimal on-demand r5.large 2>&1); then
   printf "${RED}FAIL: Invalid type r5.large was accepted.${NC}\n"
else
   if [[ "$output" == *"Error: Instance type r5.large is NOT allowed"* ]]; then
     printf "${GREEN}PASS: Invalid type r5.large correctly rejected.${NC}\n"
   else
     printf "${RED}FAIL: Script failed but not due to validation? Output:${NC}\n$output\n"
   fi
fi

# 3. Invalid Type with Force Bypass
export FORCE_INSTANCE_TYPE=true
if output=$($MANAGED_SCRIPT 1.30 us-east-1 minimal on-demand r5.large 2>&1); then
   # Should pass validation, might fail dry-run
   if [[ "$output" == *"Error: Instance type"* ]]; then
     printf "${RED}FAIL: Force bypass failed.${NC}\n"
   else
     printf "${GREEN}PASS: Force bypass worked for r5.large.${NC}\n"
   fi
else
   if [[ "$output" == *"Error: Instance type"* ]]; then
     printf "${RED}FAIL: Force bypass failed (validation error present).${NC}\n"
   else
     printf "${GREEN}PASS: Force bypass worked (script failed elsewhere).${NC}\n"
   fi
fi
unset FORCE_INSTANCE_TYPE

# 4. Multi-AMI Invalid Type (Exported)
export CUSTOM_AMI_1="ami-0a7" INSTANCE_TYPE_1="r5.large"
export CUSTOM_AMI_2="ami-0b8" INSTANCE_TYPE_2="t3.medium"
if output=$($MANAGED_SCRIPT 1.30 us-east-1 minimal multi-ami 2>&1); then
   printf "${RED}FAIL: Multi-AMI invalid type accepted.${NC}\n"
else
   if [[ "$output" == *"Error: Instance type r5.large is NOT allowed"* ]]; then
     printf "${GREEN}PASS: Multi-AMI invalid type correctly rejected.${NC}\n"
   else
     printf "${RED}FAIL: Multi-AMI check failed with unexpected error:${NC}\n$output\n"
   fi
fi
unset CUSTOM_AMI_1 INSTANCE_TYPE_1 CUSTOM_AMI_2 INSTANCE_TYPE_2

echo "========================================================"
echo "Tests Completed"
echo "========================================================"
