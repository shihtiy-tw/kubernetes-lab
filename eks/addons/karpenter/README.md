# karpenter
**Category**: Autoscaling | **Source**: OCI Helm | **Platform**: EKS
## Overview
Just-in-time node provisioning for Kubernetes. More efficient than Cluster Autoscaler.
## Prerequisites
- EKS with OIDC, SQS queue for interruption handling, IAM roles
## Quick Start
```bash
./install.sh --cluster my-cluster
# Create NodePool and EC2NodeClass resources
```
## See Also
- [Karpenter Docs](https://karpenter.sh/)
