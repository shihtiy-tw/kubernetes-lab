# EKS (Amazon Elastic Kubernetes Service)

**Status**: 🔵 Active (Migrated)  
**Platform**: Amazon Web Services (AWS)  
**CLI**: `aws`, `eksctl`

---

## Prerequisites

1. **AWS CLI** installed and configured
   ```bash
   # Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
   aws configure
   ```

2. **eksctl** installed
   ```bash
   # https://eksctl.io/introduction/#installation
   ```

3. **kubectl** installed
   ```bash
   # https://kubernetes.io/docs/tasks/tools/
   ```

4. **Helm** (for addons)
   ```bash
   # https://helm.sh/docs/intro/install/
   ```

---

## Quick Start

### Create a Cluster

```bash
# Basic cluster using eksctl
eksctl create cluster \
    --name my-cluster \
    --region us-west-2 \
    --nodegroup-name standard-nodes \
    --node-type t3.medium \
    --nodes 3
```

### Install Addons

```bash
# AWS Load Balancer Controller
cd addons/aws-load-balancer-controller
./build.sh latest

# EBS CSI Driver
cd addons/aws-ebs-csi-driver
./build.sh latest
```

### Deploy a Scenario

```bash
# ALB with HTTPS
cd scenarios/load-balancers/alb-https
./build.sh
```

---

## Directory Structure

```
eks/
├── addons/                 # EKS-specific addons and controllers
├── clusters/               # Cluster and resource configurations
├── nodegroups/             # Node group definitions
├── scenarios/              # Implementation patterns and use cases
├── tests/                  # Integration tests (KUTTL)
└── utils/                  # Helper utilities
```

---

## Cost Warning

> ⚠️ **EKS incurs real costs!** Always delete clusters and associated resources (LBs, EBS volumes) when not in use.

**Estimated costs** (us-west-2, as of 2024):
- EKS Control Plane: ~$0.10/hour
- t3.medium node: ~$0.04/hour

**Cost optimization tips**:
1. Use **Karpenter** for efficient node provisioning
2. Use **Spot Instances** for non-production workloads
3. Enable **Consolidation** in Karpenter to minimize idle resources

---

## See Also

- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [eksctl Documentation](https://eksctl.io/)
