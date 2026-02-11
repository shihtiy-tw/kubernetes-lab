#!/bin/bash
# =============================================================================
# validate-instance.sh - Shared Instance Type Validation Logic
# =============================================================================
#
# Usage:
#   source ./utils/validate-instance.sh
#   validate_instance_type <instance_type>
#
# Constraints:
#   - EC2: t3.*, t4g.*, c5.*, m5.large, m5.xlarge
#   - RDS: t3.*, t4g.* (Reminder only)
#
# Bypass:
#   export FORCE_INSTANCE_TYPE=true
# =============================================================================

# ANSI color codes (if not already defined)
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

validate_instance_type() {
  local instance_type="$1"

  # 0. Check for empty input
  if [[ -z "$instance_type" ]]; then
    printf "${RED}Error: No instance type provided for validation.${NC}\n" >&2
    return 1
  fi

  # 1. Print RDS Constraint Reminder
  printf "${BLUE}[Reminder] RDS instances are restricted to t3.* and t4g.* families only.${NC}\n" >&2

  # 2. Check for Bypass
  if [[ "${FORCE_INSTANCE_TYPE:-false}" == "true" ]]; then
    printf "${YELLOW}[WARNING] Validation bypassed via FORCE_INSTANCE_TYPE. Using %s${NC}\n" "$instance_type" >&2
    return 0
  fi

  # 3. Check against Allowed Patterns
  # Allowed: t3.*, t4g.*, c5.*, m5.large, m5.xlarge
  if [[ "$instance_type" =~ ^t3\..* ]] || \
     [[ "$instance_type" =~ ^t4g\..* ]] || \
     [[ "$instance_type" =~ ^c5\..* ]] || \
     [[ "$instance_type" == "m5.large" ]] || \
     [[ "$instance_type" == "m5.xlarge" ]]; then

    printf "${GREEN}Instance type %s is allowed.${NC}\n" "$instance_type" >&2
    return 0
  else
    printf "${RED}Error: Instance type %s is NOT allowed.${NC}\n" "$instance_type" >&2
    printf "${RED}Allowed types: t3.*, t4g.*, c5.*, m5.large, m5.xlarge${NC}\n" >&2
    printf "${RED}To bypass, export FORCE_INSTANCE_TYPE=true${NC}\n" >&2
    return 1
  fi
}
