# Research: Platform-Aware Wrapper Scripts

**Feature**: 005-platform-aware-wrappers
**Date**: 2026-02-09

## Decision: Unified Dispatcher with Parameter Translation

We will implement a suite of Bash wrapper scripts in the root `scripts/` directory. These scripts will act as a unified entry point, translating a standardized CLI interface into the specific flags required by each platform's underlying implementation.

### Rationale
- **Consistency**: Users shouldn't need to remember if it's `--region`, `--zone`, or `--location` for a specific cloud.
- **Root Execution**: Centralizing wrappers in `scripts/` allows execution from the repository root without directory switching.
- **Dry-Run Parity**: By implementing dry-run at the wrapper level, we can show exactly which platform-specific script would be called and with what arguments.

### Technical Mapping Strategy

| Generic Flag | Kind | EKS | GKE | AKS |
|--------------|------|-----|-----|-----|
| `--name`     | `--name` | `--name` | `--name` | `--name` |
| `--region`   | N/A | `--region` | `--region` | `--location` |
| `--version`  | N/A | `--k8s-version` | `--k8s-version` | `--k8s-version` |
| `--cni`      | N/A | `--cni` | `--cni` | `--cni` |
| `--project`  | N/A | N/A | `--project` | `--resource-group`* |

*\*Note: For AKS, we will default the resource group to the cluster name if `--project` is used, or allow an explicit `--resource-group` flag.*

## Alternatives Considered

1. **Option A: Symbolic Links**: Create symlinks in the root pointing to platform scripts.
   - **Rejected**: Doesn't solve the parameter inconsistency problem (e.g., `--region` vs `--location`).
2. **Option B: Makefile Targets**: Use `make create-cluster PLATFORM=eks`.
   - **Rejected**: Harder to implement complex flag parsing and validation in Make compared to Bash. Good as an entry point for humans, but wrappers are better for automation.
3. **Option C: Unified Python CLI**: A full Python application.
   - **Rejected**: Adds heavy dependency (Python + packages) to a project that is currently almost entirely Bash/K8s manifests. Bash is more "native" to this environment.

## Best Practices for Bash Wrappers

- **Use `set -euo pipefail`**: Ensure scripts fail fast on errors.
- **Array forwarding**: Use `"${REMAINING_ARGS[@]}"` to pass unmapped flags directly to underlying scripts to maintain flexibility.
- **Pre-flight checks**: Check for the existence of platform scripts before execution to provide clear error messages.
