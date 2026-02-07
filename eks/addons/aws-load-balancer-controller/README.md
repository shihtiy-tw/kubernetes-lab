# aws-load-balancer-controller
**Category**: Networking | **Source**: Helm | **Platform**: EKS
## Overview
Provisions AWS ALB/NLB for Kubernetes Ingress and LoadBalancer services.
## Prerequisites
- EKS cluster with OIDC provider
- IRSA role with AWSLoadBalancerControllerIAMPolicy
## Quick Start
```bash
./install.sh --cluster my-cluster
```
## See Also
- [AWS LB Controller Docs](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
