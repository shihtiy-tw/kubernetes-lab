# Plan: Cloud Platform Implementation

## Goal
Implement GKE and AKS support in `kubernetes-lab` following the strict Spec 002 interface.

## Phases

### Phase 1: GKE Implementation
- [ ] Create `gke/clusters/gke-cluster-create.sh` (Standard API)
- [ ] Create `gke/clusters/gke-cluster-delete.sh` (Standard API)
- [ ] Implement essential GKE addons (Ingress, Workload Identity)

### Phase 2: AKS Implementation
- [ ] Create `aks/clusters/aks-cluster-create.sh` (Standard API)
- [ ] Create `aks/clusters/aks-cluster-delete.sh` (Standard API)
- [ ] Implement essential AKS addons (App Gateway, Pod Identity)

### Phase 3: Integration Tests
- [ ] Add KUTTL tests in `gke/tests/` and `aks/tests/`
- [ ] Verify `make test-all` runs against all platforms
