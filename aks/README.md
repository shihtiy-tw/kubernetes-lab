# AKS (Azure Kubernetes Service)

**Status**: 🟢 Implementation in Progress  
**Platform**: Microsoft Azure  
**CLI**: `az`

---

## Prerequisites

1. **Azure CLI** installed and configured
   ```bash
   # Install: https://docs.microsoft.com/cli/azure/install-azure-cli
   az login
   az account set --subscription YOUR_SUBSCRIPTION_ID
   ```

2. **kubectl** installed
   ```bash
   az aks install-cli
   ```

3. **Helm** (for addons)
   ```bash
   # https://helm.sh/docs/intro/install/
   ```

---

## Quick Start

### Create a Cluster

```bash
# Basic cluster
./clusters/aks-cluster-create.sh \
    --name my-cluster \
    --resource-group my-rg \
    --location eastus

# With Azure AD integration
./clusters/aks-cluster-create.sh \
    --name prod-cluster \
    --resource-group prod-rg \
    --location westus2 \
    --enable-aad \
    --node-count 3

# See all options
./clusters/aks-cluster-create.sh --help
```

### Add Node Pool

```bash
./nodegroups/aks-nodepool-create.sh \
    --name spot-pool \
    --cluster my-cluster \
    --resource-group my-rg \
    --spot \
    --min-count 0 \
    --max-count 10
```

### Install Addons

```bash
# Application Gateway Ingress Controller
./addons/appgw-ingress/install.sh \
    --cluster my-cluster \
    --resource-group my-rg \
    --appgw-name my-appgw \
    --appgw-subnet appgw-subnet

# Key Vault CSI Driver
./addons/keyvault-csi/install.sh \
    --cluster my-cluster \
    --resource-group my-rg
```

### Delete Cluster

```bash
./clusters/aks-cluster-delete.sh \
    --name my-cluster \
    --resource-group my-rg

# Also delete resource group
./clusters/aks-cluster-delete.sh \
    --name my-cluster \
    --resource-group my-rg \
    --delete-rg --force
```

---

## Directory Structure

```
aks/
├── addons/                 # AKS-specific addons
│   ├── appgw-ingress/      # Application Gateway Ingress Controller
│   └── keyvault-csi/       # Key Vault CSI Driver
├── clusters/               # Cluster lifecycle scripts
│   ├── aks-cluster-create.sh
│   └── aks-cluster-delete.sh
├── nodegroups/             # Node pool management
│   └── aks-nodepool-create.sh
├── scenarios/              # Usage examples (WIP)
├── tests/                  # Integration tests (WIP)
└── utils/                  # Helper functions
```

---

## Cost Warning

> ⚠️ **AKS incurs real costs!** Always delete clusters when not in use.

**Estimated costs** (East US, as of 2024):
- AKS management: Free for standard tier
- Standard_DS2_v2 node: ~$0.10/hour

**Cost optimization tips**:
1. Use `--spot` for interruptible workloads
2. Enable autoscaling with `--min-count 0`
3. Use B-series VMs for dev/test

---

## Troubleshooting

### Cannot create cluster
```bash
# Check quotas
az vm list-usage --location eastus -o table

# Check provider registration
az provider show --namespace Microsoft.ContainerService
```

### Authentication issues
```bash
az login
az aks get-credentials --resource-group RG --name CLUSTER
```

### Node pool not scaling
```bash
# Check cluster autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler
```

---

## See Also

- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
- [Key Vault CSI Driver](https://docs.microsoft.com/azure/aks/csi-secrets-store-driver)
