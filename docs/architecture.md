# Architecture Overview

This document describes the high-level architecture of `kubernetes-lab`, a standardized, test-driven Kubernetes Lab framework for rapid environment reproduction across multiple cloud providers.

## Vision

Build a standardized Kubernetes Lab framework that can be deployed instantly across **AWS (EKS), Azure (AKS), GCP (GKE), and Kind**. The goal is to eliminate the latency of "starting from zero" when reproducing environments for troubleshooting and development.

## Core Component Matrix

For every scenario, the engine defines equivalent resources across platforms:

1.  **Compute Workloads**: `Pod`, `ReplicaSet`, `Deployment`, `DaemonSet`, `StatefulSet`.
2.  **Network Architecture**: `Service`, `Ingress`, `API Gateway`.
3.  **Infrastructure Abstraction**: 
    - **CNI**: AWS VPC CNI, Calico, Azure CNI, etc.
    - **CSI**: EBS, Managed Disk, Local Storage, etc.
4.  **Operational Addons**:
    - **Observability**: Prometheus/Grafana stack.
    - **Scaling**: HPA/VPA configurations.
    - **Security**: Network Policies, OPA/Gatekeeper.

## Directory Structure

```
kubernetes-lab/
├── eks/                 # AWS EKS implementation
├── gke/                 # Google GKE implementation (placeholder)
├── aks/                 # Azure AKS implementation (placeholder)
├── kind/                # Local Kind cluster implementation
├── shared/              # Cross-platform plugins, manifests, charts
│   ├── lib/             # Bash libraries
│   └── config/          # Common configurations
├── docs/                # Documentation
└── tests/               # Integration tests (KUTTL)
```

Each platform implementation (`eks/`, `kind/`, etc.) contains:
- `addons/`: Platform-specific add-on installers.
- `clusters/`: Cluster definition configurations.
- `scenarios/`: Multi-addon workflows and usage patterns.
- `tests/`: Platform-specific integration tests.

## Addon Architecture

Addons follow a consistent 12-factor CLI structure:
- `install.sh`: Main installer with `--help`, `--version`, `--dry-run`.
- `uninstall.sh`: Clean teardown of resources.
- `values/`: Helm value overrides.
- `manifests/`: Raw Kubernetes manifests.

## Technical Standards

- **CLI Compliance**: All scripts must support standard flags (`--cluster`, `--namespace`, `--dry-run`).
- **Error Handling**: `set -euo pipefail` and proper cleanup traps in all scripts.
- **Security**: No secrets in code; use external secret providers or KMS where applicable.
- **Validation**: Every scenario includes automated verification (e.g., `verify.sh` or KUTTL tests).

---
*Last updated: 2026-02-11*
