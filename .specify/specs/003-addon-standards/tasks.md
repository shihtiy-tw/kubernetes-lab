# Tasks: Addon Implementation

## Phase 1: Shared Addons
- [x] `shared/addons/cert-manager/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `shared/addons/metrics-server/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `shared/addons/ingress-nginx/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `shared/addons/external-dns/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `shared/addons/prometheus-stack/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `shared/addons/argocd/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `shared/addons/external-secrets/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `shared/addons/keda/` - install.sh, uninstall.sh, upgrade.sh, README.md

## Phase 2: EKS Addons
- [x] `eks/addons/aws-load-balancer-controller/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `eks/addons/cluster-autoscaler/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `eks/addons/karpenter/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `eks/addons/aws-ebs-csi-driver/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `eks/addons/eks-pod-identity-agent/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `eks/addons/cloudwatch-observability/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `eks/addons/secrets-store-csi-driver/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `eks/addons/aws-efs-csi-driver/` - install.sh, uninstall.sh, upgrade.sh, README.md

## Phase 3: GKE Addons
- [x] `gke/addons/workload-identity/` - Already done
- [x] `gke/addons/config-connector/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `gke/addons/cloud-sql-proxy/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `gke/addons/filestore-csi/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `gke/addons/cloud-armor/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `gke/addons/anthos-service-mesh/` - install.sh, uninstall.sh, upgrade.sh, README.md

## Phase 4: AKS Addons
- [x] `aks/addons/appgw-ingress/` - Already done
- [x] `aks/addons/keyvault-csi/` - Already done
- [x] `aks/addons/aad-pod-identity/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `aks/addons/azure-disk-csi/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `aks/addons/azure-file-csi/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `aks/addons/azure-policy/` - install.sh, uninstall.sh, upgrade.sh, README.md

## Phase 5: Kind Addons
- [x] `kind/addons/local-path-provisioner/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `kind/addons/metallb/` - install.sh, uninstall.sh, upgrade.sh, README.md
- [x] `kind/addons/registry/` - install.sh, uninstall.sh, upgrade.sh, README.md

## Verification
- [x] Run `--help` on all install scripts
- [x] Run `--version` on all install scripts
- [x] Verify idempotency by running install twice
- [x] Test uninstall on a Kind cluster
