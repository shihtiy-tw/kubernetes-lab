# Configuration Examples

This directory contains example configurations for kubernetes-lab addons and deployments.

## Structure

```
examples/
├── README.md               # This file
├── helm-values/            # Helm value overrides
│   ├── ingress-nginx/
│   ├── cert-manager/
│   └── ...
├── kustomize/              # Kustomize overlays
│   ├── base/
│   └── overlays/
├── manifests/              # Raw Kubernetes manifests
│   ├── namespace.yaml
│   └── ...
└── environments/           # Environment-specific configs
    ├── dev/
    ├── staging/
    └── prod/
```

## Usage

### Helm Values

Use with addon install scripts:

```bash
./eks/addons/ingress-nginx/install.sh \
  --cluster my-eks \
  --values examples/helm-values/ingress-nginx/production.yaml
```

### Kustomize

Apply overlays:

```bash
kubectl apply -k examples/kustomize/overlays/production
```

### Raw Manifests

Apply directly:

```bash
kubectl apply -f examples/manifests/namespace.yaml
```

## Environment Examples

| Environment | Use Case | Characteristics |
|-------------|----------|-----------------|
| `dev` | Local development | Minimal resources, debug enabled |
| `staging` | Testing | Production-like, reduced scale |
| `prod` | Production | HA, security hardened |

---

*Last updated: 2026-01-31*
