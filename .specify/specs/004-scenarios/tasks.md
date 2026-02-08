# Spec 004: Scenarios & Testing - Implementation Tasks

## Phase 1: General Scenarios (Platform Agnostic) ✅
- [x] 13 scenarios created

## Phase 2: Advanced Networking (CNI Specific) ✅
- [x] 2 scenarios created (cilium-l7-policy, calico-global-policy)

## Phase 3: CSP Scenarios (Platform Integration) ✅
- [x] EKS: 5 scenarios
- [x] GKE: 3 scenarios
- [x] AKS: 4 scenarios

## Phase 4: Infrastructure (Spec 002 Updates) ✅
Update cluster provisioning scripts to support CNI switching.

- [x] `kind/clusters/basic/create.sh --cni [native|cilium|calico]`
- [x] `eks/clusters/create.sh --cni [vpc|cilium|calico]`
- [x] `aks/clusters/create.sh --cni [azure|cilium|calico]`
- [x] `gke/clusters/create.sh --cni [dpv2|calico]`

## Phase 5: Automation ✅
- [x] Implement `scripts/test.sh` (KUTTL wrapper)
- [x] Create `.opencode/command/k8s.test.integration.md`

---

## ✅ SPEC 004 COMPLETE
