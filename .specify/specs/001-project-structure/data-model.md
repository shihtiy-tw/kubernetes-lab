# Data Model: Directory Schema

## Root Directory

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `.opencode/` | Directory | Agent commands and tools | Yes |
| `.specify/` | Directory | Specifications and plans | Yes |
| `.github/` | Directory | CI/CD workflows | Yes |
| `aks/` | Directory | Azure Kubernetes Service implementation | Yes |
| `eks/` | Directory | Amazon EKS implementation | Yes |
| `gke/` | Directory | Google GKE implementation | Yes |
| `kind/` | Directory | Local Kind implementation | Yes |
| `docs/` | Directory | Documentation | Yes |
| `scripts/` | Directory | Dev-loop utility scripts | Yes |
| `shared/` | Directory | Cross-platform resources | Yes |
| `tests/` | Directory | Integration tests | Yes |
| `AGENTS.md` | File | Agent context master file | Yes |
| `BACKLOG.md` | File | Work queue | Yes |
| `Makefile` | File | Build targets | Yes |
| `README.md` | File | Entry point | Yes |

## Shared Directory (`shared/`)

| Name | Type | Description |
|------|------|-------------|
| `charts/` | Directory | Local Helm charts |
| `manifests/` | Directory | Raw Kubernetes YAMLs |
| `plugins/` | Directory | Cross-platform scripts |
| `scenarios/` | Directory | High-level scenarios |
