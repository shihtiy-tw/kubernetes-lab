# Shared Kubernetes Resources

This directory contains resources, manifests, and add-ons that are platform-agnostic or shared across multiple cloud providers (EKS, GKE, AKS, Kind).

## Structure

```
shared/
└── addons/           # Platform-agnostic Helm charts and manifests
    ├── argocd
    ├── cert-manager
    ├── external-dns
    ├── external-secrets
    ├── ingress-nginx
    ├── keda
    ├── metrics-server
    └── prometheus-stack
```

## Add-on Management

Most shared add-ons include standardized scripts for lifecycle management:

- `install.sh`: Deploys the add-on using Helm or kubectl.
- `uninstall.sh`: Removes the add-on and its resources.
- `upgrade.sh`: Upgrades the add-on version or configuration.
- `status.sh`: Checks the health and status of the add-on.

### Example: Installing Ingress NGINX

```bash
cd addons/ingress-nginx
./install.sh
```

## Best Practices

1. **Platform Agnostic**: Keep manifests in this directory as generic as possible.
2. **Versioned Charts**: Use specific versions for Helm charts to ensure reproducibility.
3. **Values Files**: Provide example `values.yaml` files for common configurations.
4. **Idempotency**: Ensure installation scripts can be run multiple times without failure.
