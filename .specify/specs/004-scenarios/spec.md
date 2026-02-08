---
id: spec-004
title: Scenarios & Testing
type: standard
priority: high
status: proposed
dependencies: [spec-001, spec-002, spec-003]
tags: [testing, scenarios, kuttl, verification]
---

# Spec 004: Scenarios & Testing

## Overview
This specification defines the standard for **Usage Scenarios** within the `kubernetes-lab`. A Scenario is a self-contained, verifiable example of a Kubernetes pattern.

Scenarios serve two purposes:
1.  **Documentation**: Demonstrate how to use the platform (e.g., "How do I use IRSA on EKS?").
2.  **Verification**: continuous integration testing using KUTTL to ensure the platform and addons are functioning correctly.

## 1. Directory Structure
Scenarios are organized by **Category**, then **Scenario Name**.

```text
scenarios/
├── general/                 # Platform-agnostic (Kind/EKS/GKE/AKS)
│   ├── pod-basic/
│   ├── deployment-rolling/
│   └── ...
├── network/                 # CNI-specific scenarios
│   ├── cilium-l7-policy/
│   ├── calico-global-policy/
│   └── ...
├── eks/                     # AWS-specific integrations
│   ├── irsa-s3/
│   └── ...
├── gke/                     # GCP-specific integrations
│   ├── workload-identity/
│   └── ...
└── aks/                     # Azure-specific integrations
    ├── workload-identity/
    └── ...
```

## 2. Scenario Interface
Each scenario directory MUST contain the following files:

### 2.1 `README.md`
Documentation explaining the pattern, prerequisites, and expected outcome.

### 2.2 `manifests/`
A directory containing standard Kubernetes YAML manifests required to deploy the scenario.
- `deployment.yaml`, `service.yaml`, `ingress.yaml`, etc.
- **Rule**: No Helm charts or complex templating. Plain YAML is preferred for clarity and testability.

### 2.3 `kuttl-test.yaml`
A Kubernetes Test Toolkit (KUTTL) definition for automated verification.
- **Assert**: Defines the "success state" (e.g., Pod is Running, Service has IP).
- **TestStep**: Sequence of operations (Apply -> Wait -> Assert).

## 3. The `k8s.test.integration` Command
This spec mandates the implementation of a new operational command:
- **Command**: `.opencode/command/k8s.test.integration.md`
- **Function**: Executes KUTTL tests against a specific scenario or the entire suite.
- **Usage**:
  ```bash
  # Test a single scenario
  ./scripts/test.sh --scenario scenarios/general/pod-basic

  # Test all general scenarios
  ./scripts/test.sh --suite general
  ```

## 4. Test Matrix (CNI Variants)
A key goal of `kubernetes-lab` is verifying workloads across different networking backends.

| CNI | Kind | EKS | GKE | AKS |
|---|---|---|---|---|
| **Native** | Kindnet | VPC CNI | Dataplane V2 | Azure CNI |
| **Cilium** | Supported | Supported (Chain/Overlay) | Supported (DPv2 is Cilium-based) | Supported (BYO) |
| **Calico** | Supported | Supported | Supported | Supported |

## 5. Scenario Catalog

```markdown
### 5.1 General Scenarios
Core Kubernetes primitives and security standards that must work on all certified platforms.

- **Workloads**: Pod, Deployment, StatefulSet, DaemonSet, Job, CronJob.
- **Network**: Service (ClusterIP, NodePort), Ingress (Nginx).
- **Config**: ConfigMap, Secret.
- **Ops**: HPA (Horizontal Pod Autoscaler), PDB (Pod Disruption Budget).
- **Security**: RBAC (Roles/Bindings), NetworkPolicy (Egress/Ingress isolation), Pod Security Standards (Baseline/Restricted), and Secret Encryption.
```

### 5.2 Advanced Networking (CNI-Specific)
Scenarios that leverage specific CNI features.

| Scenario | CNI Requirement | Description |
|---|---|---|
| **cilium-l7-policy** | Cilium | HTTP-aware filtering rules |
| **cilium-hubble** | Cilium | Observability flows verification |
| **calico-global-policy** | Calico | Cluster-wide network policies |

### 5.3 CSP Scenarios
Platform-specific integrations verifying Spec 003 Addons.

```markdown
#### EKS
- **Identity**: Pod identity (IRSA) accessing AWS services.
- **Ingress**: AWS Load Balancer Controller (ALB/NLB) and VPC Lattice (Gateway API).
- **Storage**: EBS (gp3) and EFS (ReadWriteMany).
- **Scaling**: Karpenter NodePools and node provisioning.
```

#### GKE
- **Identity**: Workload Identity accessing GCP APIs.
- **Ingress**: GKE Ingress (NEG).
- **Storage**: PD-SSD and Filestore.

#### AKS
- **Identity**: Workload Identity accessing Azure resources.
- **Ingress**: App Gateway Ingress.
- **Storage**: Azure Disk and Azure File.

## 6. Success Criteria
1.  All "General" scenarios pass on Kind, EKS, GKE, and AKS.
2.  CSP scenarios pass on their respective clouds.
3.  Network scenarios pass on verified CNI configurations.
4.  Cluster provisioning scripts (Spec 002) updated to support `--cni [cilium|calico|native]` flag.
