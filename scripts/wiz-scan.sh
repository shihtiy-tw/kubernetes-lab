#!/bin/bash
# =============================================================================
# wiz-scan.sh - Pre-commit hook to scan staged files with Wiz CLI
# =============================================================================
#
# This script creates a temporary directory containing only the staged files
# and runs `wizcli scan` against it. This ensures we only scan what is about
# to be committed, not the entire repository or unstaged changes.
#
# Usage:
#   Integrated via .pre-commit-config.yaml
#
# Environment Variables:
#   WIZ_POLICY_NAME  - Policy to enforce (default: "default-policy")
#   WIZ_CONF         - Path to config file to source (default: "wiz-git-hook.conf")
#
# =============================================================================

set -e

# --- Configuration ---
# Allow overriding the policy name via env var
POLICY_NAME="${WIZ_POLICY_NAME:-default-policy}"
# Config file for creds or extra settings
WIZ_CONF="${WIZ_CONF:-wiz-git-hook.conf}"

# --- Check Prerequisites ---
# If wizcli is not in the PATH, skip the scan gracefully
if ! command -v wizcli &> /dev/null; then
    echo "[INFO] 'wizcli' command not found. Skipping Wiz Security Scan."
    exit 0
fi

# Source configuration file if it exists
if [ -f "$WIZ_CONF" ]; then
    source "$WIZ_CONF"
fi

# --- Prepare Staged Files ---
# Get list of staged files (Added, Copied, Modified, Renamed)
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)

if [ -z "$STAGED_FILES" ]; then
    echo "[INFO] No staged files to scan."
    exit 0
fi

# Create a temporary directory
TEMP_PATH=$(mktemp -d)

# Cleanup function
cleanup() {
    rm -rf "$TEMP_PATH"
}
trap cleanup EXIT

echo "[INFO] Preparing staged files for Wiz scan..."

# Copy/Link staged files to the temporary directory
# preserving the directory structure
for file in $STAGED_FILES; do
    # Skip if file somehow doesn't exist (edge case)
    if [ ! -e "$file" ]; then continue; fi

    DEST="$TEMP_PATH/$file"
    mkdir -p "$(dirname "$DEST")"

    # Try to hardlink for speed/space, fallback to copy
    if ln "$file" "$DEST" 2>/dev/null; then
        : # Linked successfully
    else
        cp "$file" "$DEST"
    fi
done

# --- Run Wiz Scan ---
echo "[INFO] Running Wiz CLI scan on staged changes..."
echo "       Directory: $TEMP_PATH"
echo "       Policy:    $POLICY_NAME"

# Note: The command structure is based on user request:
# $cli_path scan dir <DIRECTORY_PATH> . --no-publish --policy <policy_name>
# We assume <DIRECTORY_PATH> is the root to scan.
# The `.` arg might be redundant if DIR is specified, but keeping user's intent.

set +e # Allow wizcli to fail so we can handle the exit code
wizcli scan dir "$TEMP_PATH" --path . --no-publish --policy "$POLICY_NAME" 2>/dev/null
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -eq 0 ]; then
    echo "[SUCCESS] Wiz scan passed."
else
    echo "[FAILURE] Wiz scan found issues (Exit Code: $EXIT_CODE)."
    # We exit with the same code to block the commit if Wiz found issues
    exit $EXIT_CODE
fi
