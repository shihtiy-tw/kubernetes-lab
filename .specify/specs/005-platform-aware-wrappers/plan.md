# Implementation Plan: Platform-Aware Wrapper Scripts

**Branch**: `005-platform-aware-wrappers` | **Date**: 2026-02-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `.specify/specs/005-platform-aware-wrappers/spec.md`

## Summary

This feature implements a suite of "Platform-Aware" Bash wrapper scripts in the repository root (`scripts/`). These scripts (e.g., `k8s.cluster.create.sh`) provide a unified interface for laboratory operations across Kind, EKS, GKE, and AKS. The approach uses a dispatcher pattern that maps generic flags (like `--region`) to provider-specific flags (like `--location`) and forwards execution to the appropriate platform directory.

## Technical Context

**Language/Version**: Bash 4.x/5.x
**Primary Dependencies**: `kind`, `eksctl`, `gcloud`, `az`, `kubectl`, `helm`
**Database**: N/A (Filesystem based)
**Testing**: BATS for unit testing the flag translation logic
**Target Platform**: Linux/macOS
**Project Type**: CLI Wrapper Suite
**Performance Goals**: < 100ms wrapper overhead
**Constraints**: Must be executable from repo root; No sub-shells that lose exit codes.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Adherence | Justification |
|-----------|-----------|---------------|
| Cloud-Agnostic First | ✅ High | Specifically designed to hide cloud differences and unify resource naming. |
| CLI 12-Factor | ✅ High | Wrappers will strictly follow the project's 12-factor template and provide dry-run support. |
| Test-First Strategy | ✅ Med | BATS tests for flag parsing logic are included in the task list. |
| Agent 12-Factor | ✅ High | Agent context (AGENTS.md) has been updated with new command definitions. |

## Project Structure

### Documentation (this feature)

```text
.specify/specs/005-platform-aware-wrappers/
├── plan.md              # This file
├── research.md          # Research on flag mapping and dispatcher patterns
├── data-model.md        # Mapping definitions
├── quickstart.md        # Examples of unified commands
└── tasks.md             # Implementation steps (to be generated)
```

### Source Code (repository root)

```text
scripts/
├── k8s.cluster.create.sh   # Unified cluster creation
├── k8s.cluster.delete.sh   # Unified cluster deletion
├── k8s.addon.install.sh    # Unified addon installation
├── k8s.logs.sh             # Unified log retrieval
└── k8s.scenario.run.sh      # Unified lab scenario deployment
```

## Structure Decision

The **Dispatcher Pattern** is selected. Root scripts will handle the `--platform` flag and common parameter mapping, then `exec` or call the platform-specific scripts in their respective directories. 

**Key Design Decisions**:
1. **Naming Convention**: Clusters and contexts will be named following the pattern `{platform}-{version}-{config}-{name}` to ensure uniqueness and auditability.
2. **Explicit Mapping**: Common flags (`--region`, `--project`, `--version`, `--config`) are explicitly mapped to platform-specific equivalents.
3. **Array-based Forwarding**: Remaining arguments are forwarded using Bash arrays (`"${FORWARD_ARGS[@]}"`) to preserve quoting.
4. **Interactive Safety**: `k8s.cluster.delete.sh` will prompt for confirmation unless `--yes` or `--force` is provided.
5. **Dependency Validation**: Before dispatching, the wrapper verifies the required platform CLI (e.g., `eksctl`) is in the PATH and issues a warning if the version is outdated.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations identified.
