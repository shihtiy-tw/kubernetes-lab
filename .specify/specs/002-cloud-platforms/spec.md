---
id: spec-002
title: Cloud Platform Implementation Standard
type: standard
priority: critical
status: proposed
dependencies: [spec-001]
tags: [governance, cloud, standards]
---

# Spec 002: Cloud Platform Implementation Standard

## Overview
This specification defines the strict contract for implementing a cloud provider (e.g., EKS, GKE, AKS) within the `kubernetes-lab`. Uniformity enables the platform-aware command system (`k8s.cluster.create`, etc.) to function reliably.

## Standard Directory Structure
Every platform module (`eks/`, `gke/`, `aks/`) MUST adhere to this layout:

```text
<platform>/
├── addons/             # Platform-specific add-on installation scripts
├── clusters/           # Cluster creation/deletion scripts
├── nodegroups/         # Node pool/group management
├── scenarios/          # Platform-specific usage scenarios
├── tests/              # Platform-specific integration tests
├── utils/              # Helper functions for this platform
└── README.md           # Platform-specific documentation
```

## CLI Script Standards (12-Factor)
All scripts in `clusters/`, `addons/`, and `scenarios/` MUST:
1. Support `--help` and `--version`.
2. Support `--dry-run` where applicable.
3. Use strict mode (`set -euo pipefail`).
4. Be idempotent (safe to run multiple times).

### Cluster Management (`clusters/`)
Required scripts:
- `<platform>-cluster-create.sh`: Provisions a cluster.
  - **Required Flags**: `--name`, `--region` (or `--zone`), `--node-count`.
- `<platform>-cluster-delete.sh`: Destroys a cluster.
  - **Required Flags**: `--name`, `--region`.

### Addon Management (`addons/`)
Each addon is a directory containing at least an `install.sh` and `remote-remove.sh` (or `uninstall.sh`).
- Naming: `<platform>/addons/<addon-name>/install.sh`
- Standard: Must accept target cluster context or name via flags.

### Scenarios (`scenarios/`)
Demonstrate specific capabilities of the platform.
- Structure: `<platform>/scenarios/<category>/<scenario-name>/`
- Entry point: `deploy.sh` and `destroy.sh`.

## Integration Testing
- Each platform MUST support KUTTL tests.
- `tests/` directory must contain a `run-all.sh` orchestrator.

## Naming Conventions
- Scripts: `kebab-case.sh`
- Functions: `snake_case`
- Variables: `UPPER_CASE`
- Kubernetes Resources: `kebab-case`

## Documentation
- `README.md` at the platform root MUST contain:
  - Prerequisites (CLI tools, permissions).
  - Quick start.
  - Cost warning (for public clouds).
