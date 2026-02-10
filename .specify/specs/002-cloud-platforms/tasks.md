# Tasks: Cloud Platform Compliance

**Input**: Design documents from `.specify/specs/002-cloud-platforms/`
**Prerequisites**: plan.md (required), spec.md (required)

## Phase 1: GKE Compliance (User Story 1)

- [ ] T001 Create kubernetes-lab/gke/clusters/gke-cluster-create.sh with --help, --version, --dry-run
- [ ] T002 Create kubernetes-lab/gke/clusters/gke-cluster-delete.sh with confirmation prompt
- [ ] T003 [P] Implement install scripts for essential GKE addons in kubernetes-lab/gke/addons/
- [ ] T004 [P] Update kubernetes-lab/gke/README.md with GKE specific prerequisites

## Phase 2: AKS Compliance (User Story 2)

- [ ] T005 Create kubernetes-lab/aks/clusters/aks-cluster-create.sh with --help, --version, --dry-run
- [ ] T006 Create kubernetes-lab/aks/clusters/aks-cluster-delete.sh with confirmation prompt
- [ ] T007 [P] Implement install scripts for essential AKS addons in kubernetes-lab/aks/addons/
- [ ] T008 [P] Update kubernetes-lab/aks/README.md with AKS specific prerequisites
