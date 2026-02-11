# argocd
**Category**: GitOps | **Source**: Helm | **Platforms**: All
## Overview
GitOps continuous delivery tool for Kubernetes.
## Quick Start
```bash
./install.sh
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
# Access UI
kubectl port-forward svc/argocd-server 8080:443 -n argocd
```
## See Also
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
