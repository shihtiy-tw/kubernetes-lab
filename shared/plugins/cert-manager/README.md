# cert-manager

**Category**: TLS/Security  
**Source**: Helm (jetstack/cert-manager)  
**Platforms**: All (shared)

## Overview
cert-manager automates the management and issuance of TLS certificates from various sources (Let's Encrypt, Vault, self-signed, etc).

## Prerequisites
- Kubernetes 1.22+
- Helm 3.x
- kubectl configured

## Quick Start

```bash
# Install
./install.sh

# With specific version
./install.sh --version 1.14.0

# Check status
./status.sh
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--namespace` | Target namespace | cert-manager |
| `--version` | Chart version | latest |
| `--values` | Custom values file | - |

## Example: Let's Encrypt ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

## Troubleshooting

```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate status
kubectl get certificates -A
kubectl describe certificate <name>

# Check certificate requests
kubectl get certificaterequests -A
```

## See Also
- [cert-manager Documentation](https://cert-manager.io/docs/)
