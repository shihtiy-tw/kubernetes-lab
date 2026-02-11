# Implementation Plan: Platform-Aware Wrapper Scripts

**Branch**: `005-platform-aware-wrappers` | **Date**: 2026-02-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `.specify/specs/005-platform-aware-wrappers/spec.md`

## Summary

This feature implements a suite of "Platform-Aware" Bash wrapper scripts in the repository root (`scripts/`). These scripts (e.g., `k8s.cluster.create.sh`) provide a unified interface for laboratory operations across Kind, EKS, GKE, and AKS. The approach uses a dispatcher pattern that maps generic flags (like `--region`) to provider-specific flags (like `--location`) and forwards execution to the appropriate platform directory.

## Technical Context

**Language/Version**: Bash 4.x/5.x
**Primary Dependencies**: `kind`, `eksctl`, `gcloud`, `az`, `kubectl`, `helm`
**Storage**: N/A
**Testing**: BATS for unit testing the flag translation logic
**Target Platform**: Linux/macOS
**Project Type**: CLI Wrapper Suite
**Performance Goals**: < 100ms wrapper overhead
**Constraints**: Must be executable from repo root; No sub-shells that lose exit codes.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Adherence | Justification |
|-----------|-----------|---------------|
| Cloud-Agnostic First | ✅ High | Specifically designed to hide cloud differences. |
| CLI 12-Factor | ✅ High | Wrappers will strictly follow the project's 12-factor template. |
| Test-First Strategy | ✅ Med | Unit tests for flag parsing will be added. |
| Agent 12-Factor | ✅ High | Updating agent context to include these new commands. |

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
└── k8s.logs.sh             # Unified log retrieval
```

## Structure Decision

The **Dispatcher Pattern** is selected. Root scripts will handle the `--platform` flag and common parameter mapping, then `exec` or call the platform-specific scripts in their respective directories. This maintains the modularity of each platform while providing the requested root-level execution.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations identified.
