# Tasks: Addon Standards Implementation

**Input**: Design documents from `.specify/specs/003-addon-standards/`
**Prerequisites**: plan.md (required), spec.md (required)

## Phase 1: Shared Addons Standardization (User Story 1)

- [x] T001 Standardize shared/addons/cert-manager/ (install, uninstall, upgrade, README)
- [x] T002 Standardize shared/addons/metrics-server/ (install, uninstall, upgrade, README)
- [x] T003 Standardize shared/addons/ingress-nginx/ (install, uninstall, upgrade, README)
- [x] T004 Standardize shared/addons/external-dns/ (install, uninstall, upgrade, README)
- [x] T005 Standardize shared/addons/prometheus-stack/ (install, uninstall, upgrade, README)
- [x] T006 Standardize shared/addons/argocd/ (install, uninstall, upgrade, README)
- [x] T007 Standardize shared/addons/external-secrets/ (install, uninstall, upgrade, README)
- [x] T008 Standardize shared/addons/keda/ (install, uninstall, upgrade, README)

## Phase 2: Platform Specific Addons (User Story 2)

- [x] T009 Standardize EKS addons (LB Controller, Autoscaler, Karpenter, EBS CSI, Pod Identity, etc.)
- [x] T010 Standardize GKE addons (Config Connector, SQL Proxy, Filestore CSI, Cloud Armor, ASM)
- [x] T011 Standardize AKS addons (AAD Pod ID, Disk CSI, File CSI, Azure Policy)
- [x] T012 Standardize Kind addons (Local Path, MetalLB, Registry)

## Phase 3: Verification & Compliance

- [ ] T013 [P] Run --help validation on all standardized install scripts
- [ ] T014 [P] Run --version validation on all standardized install scripts
- [ ] T015 Verify idempotency of install scripts (double run test)
- [ ] T016 Perform end-to-end uninstall test on Kind cluster
