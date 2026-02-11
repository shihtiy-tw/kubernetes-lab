# Data Model: Flag Mapping Matrix

This document defines the mapping between generic flags used by the wrapper scripts and the provider-specific flags required by the underlying platform scripts.

## Platform Dispatcher Table

| Platform | Mapping Directory | Underlying Entry Point |
|----------|-------------------|-------------------------|
| `kind`   | `./kind/`         | `./kind/clusters/kind-cluster-create.sh` |
| `eks`    | `./eks/`          | `./eks/clusters/create.sh` |
| `gke`    | `./gke/`          | `./gke/clusters/create.sh` |
| `aks`    | `./aks/`          | `./aks/clusters/create.sh` |

## Flag Mapping Logic

| Generic Flag | Logic / Mapping | Target Env Var (Optional) |
|--------------|-----------------|--------------------------|
| `--platform` | Used for dispatching. Internal to wrapper. | `K8S_PLATFORM` |
| `--name`     | Pass through as `--name`. | `CLUSTER_NAME` |
| `--region`   | Maps to `--region` (EKS/GKE), `--location` (AKS). | `AWS_REGION`, `GOOGLE_REGION`, `AZURE_LOCATION` |
| `--project`  | Maps to `--project` (GKE), `--resource-group` (AKS). | `GOOGLE_PROJECT`, `AZURE_RESOURCE_GROUP` |
| `--version`  | Maps to `--k8s-version`. | `K8S_VERSION` |
| `--cni`      | Pass through as `--cni`. Validation per platform. | `CNI_PLUGIN` |

## Validation Rules

1. **Platform Validation**: Must be one of `[kind, eks, gke, aks]`. Fail with exit code 1 if invalid.
2. **Dependency Validation**: Before execution, verify the required binary exists in PATH:
   - `kind` -> `kind`
   - `eks` -> `eksctl`
   - `gke` -> `gcloud`
   - `aks` -> `az`
3. **Requirement Validation**: Certain platforms require specific flags (e.g., GKE requires project). Fail with clear error message if missing.
