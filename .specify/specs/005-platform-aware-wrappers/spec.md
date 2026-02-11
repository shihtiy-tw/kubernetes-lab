---
id: spec-005
title: Platform-Aware Wrapper Scripts
type: standard
priority: critical
status: draft
tags: [automation, cli, infrastructure]
---

# Feature Specification: Platform-Aware Wrapper Scripts

**Feature Branch**: `005-platform-aware-wrappers`  
**Created**: 2026-02-09  
**Status**: Draft  
**Input**: User description: "Unified platform-aware wrapper scripts for k8s.cluster and k8s.addon operations (kind, EKS, GKE, AKS) to provide a consistent CLI interface across all providers."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unified Cluster Lifecycle (Priority: P1)

As a Developer or CI/CD Pipeline, I want to use a single command to create or delete a Kubernetes cluster regardless of the underlying cloud provider, so that I can switch environments without changing my automation logic.

**Why this priority**: This is the core functionality that enables cloud-agnostic laboratory operations.

**Independent Test**: Can be fully tested by running `k8s.cluster.create.sh --platform kind --name test-cluster --dry-run` and verifying it generates the correct Kind commands.

**Acceptance Scenarios**:

1. **Given** I am on a machine with `kind` installed, **When** I run `k8s.cluster.create.sh --platform kind --name dev-local`, **Then** a local Kind cluster is created and my `kubectl` context is updated.
2. **Given** I have AWS credentials configured, **When** I run `k8s.cluster.create.sh --platform eks --name prod-cluster --region us-west-2`, **Then** an EKS cluster is created via `eksctl` and credentials are merged into my kubeconfig.

---

### User Story 2 - Consistent Addon Management (Priority: P2)

As a DevOps Engineer, I want to install standard addons (like ingress-nginx or cert-manager) using a unified command that automatically handles platform-specific configurations, so that my operational stack remains consistent across clouds.

**Why this priority**: Ensures that the "operational environment" is the same everywhere, simplifying troubleshooting.

**Independent Test**: Run `k8s.addon.install.sh --platform aks --addon ingress-nginx --cluster my-aks --dry-run` and verify it identifies the correct Azure-specific Helm values or manifests.

**Acceptance Scenarios**:

1. **Given** a healthy EKS cluster, **When** I run `k8s.addon.install.sh --platform eks --addon ingress-nginx --cluster my-eks`, **Then** the Ingress NGINX controller is installed with AWS-specific LoadBalancer annotations.
2. **Given** a local Kind cluster, **When** I run `k8s.addon.install.sh --platform kind --addon metrics-server --cluster kind-kind`, **Then** the metrics-server is installed with the `kubelet-insecure-tls` argument required for Kind.

---

### User Story 3 - Unified Observability & Logs (Priority: P3)

As a Support Engineer, I want to retrieve logs from any cluster using a unified tool that abstracts away provider-specific logging interfaces (CloudWatch, Azure Monitor, Stackdriver), so that I can debug issues quickly.

**Why this priority**: Reduces the cognitive load and tool-switching overhead during troubleshooting.

**Independent Test**: Run `k8s.logs.sh --platform gke --cluster test --deployment nginx --dry-run` and verify it maps to the correct `gcloud` or `kubectl` log command.

**Acceptance Scenarios**:

1. **Given** a deployment in an AKS cluster, **When** I run `k8s.logs.sh --platform aks --cluster my-aks --deployment nginx`, **Then** I see the aggregated logs from all pods in that deployment.

---

### Edge Cases

- **Invalid Platform**: What happens when an unsupported platform (e.g., `openshift`) is provided?
- **Missing Dependencies**: How does the system handle missing CLI tools (e.g., `eksctl` missing when target is `eks`)?
- **Partial Failure**: If a cluster creation succeeds but kubeconfig update fails, how is the state reported?
- **Credential Timeout**: Handling expired cloud sessions during long-running operations.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a unified entry point for cluster operations: `k8s.cluster.create.sh`, `k8s.cluster.delete.sh`.
- **FR-002**: The system MUST provide a unified entry point for addon management: `k8s.addon.install.sh`.
- **FR-003**: All scripts MUST support the `--platform` flag with values: `kind`, `eks`, `gke`, `aks`.
- **FR-004**: Scripts MUST validate that required platform-specific CLI tools (`kind`, `eksctl`, `gcloud`, `az`) are installed before execution.
- **FR-005**: Scripts MUST follow the CLI 12-Factor principles as defined in the Project Constitution (e.g., `--help`, `--version`, `--dry-run`).
- **FR-006**: Addon installation MUST support platform-aware overrides (e.g., using different Helm values for EKS vs. AKS).
- **FR-007**: The system MUST support a global configuration or environment variables for default values (e.g., `DEFAULT_REGION`, `DEFAULT_PROJECT`).

### Key Entities

- **Platform**: The target Kubernetes provider (kind, eks, gke, aks).
- **Cluster**: A named Kubernetes instance on a specific Platform.
- **Addon**: An operational component (ingress, monitoring, etc.) that can be installed on a Cluster.
- **Context**: The `kubectl` credentials and configuration for a specific Cluster.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer can provision a "General" scenario (Pod + Ingress) on a new platform using less than 3 unique commands.
- **SC-002**: All platform-aware scripts return a non-zero exit code and a clear error message when required dependencies are missing.
- **SC-003**: 100% of wrapper scripts respond to `--help` and `--version` flags.
- **SC-004**: Deployment of a standard scenario across 3 different platforms (e.g., Kind, EKS, AKS) takes less than 30 minutes of total human effort.

## Assumptions

- **A-001**: Users have already authenticated with their respective cloud providers (AWS, GCP, Azure) before running cloud-specific commands.
- **A-002**: `kubectl` is installed and available in the system PATH.
- **A-003**: Helm is used as the primary engine for addon installation.
