# Spec 004 Plan: Scenarios & Testing

## Phase 1: Foundation (General Scenarios)
Verify core Kubernetes functionality works everywhere.
- [ ] `scenarios/general/pod-basic/` (Smoke test)
- [ ] `scenarios/general/network-policy-basic/` (Verify CNI exists)
- [ ] `scenarios/general/ingress-nginx/` (Verify Ingress Controller)

## Phase 2: Spec 002 Updates (CNI Support)
Update cluster provisioning scripts to support CNI switching.
- [ ] `kind/clusters/kind-cluster-create.sh --cni [native|cilium|calico]`
- [ ] `eks/clusters/eks-cluster-create.sh --cni [vpc|cilium|calico]`
- [ ] `aks/clusters/aks-cluster-create.sh --cni [azure|cilium|calico]`
- [ ] `gke/clusters/gke-cluster-create.sh --cni [dpv2|calico]`

## Phase 3: Advanced Networking Scenarios
Verify specific CNI capabilities.
- [ ] `scenarios/network/cilium-l7-policy/`
- [ ] `scenarios/network/calico-global-policy/`

## Phase 4: CSP Integration Scenarios
Verify Cloud Provider integration (Spec 003).
- [ ] `scenarios/eks/alb-ingress/`
- [ ] `scenarios/gke/workload-identity/`
- [ ] `scenarios/aks/azure-disk/`

## Phase 5: Automation
- [ ] Implement `.opencode/command/k8s.test.integration.md` (KUTTL wrapper)
- [ ] Create `kuttl-test.yaml` for all Phase 1 scenarios.
