# Quick Start Guide

Get started with kubernetes-lab in 5 minutes.

## Prerequisites

Before you begin, ensure you have:

- **kubectl** (v1.25+)
- **helm** (v3.10+)
- **kind** (v0.20+) for local development
- **aws-cli** (v2.x) for EKS

Verify installation:
```bash
./scripts/check-versions.sh
```

## Option 1: Local Development with Kind

### Step 1: Create a Kind Cluster

```bash
./kind/create-cluster.sh --name dev-cluster
```

This creates a local Kubernetes cluster with:
- 1 control plane node
- 2 worker nodes
- Ingress-ready configuration

### Step 2: Verify the Cluster

```bash
kubectl cluster-info
kubectl get nodes
```

### Step 3: Install Your First Addon

```bash
./eks/addons/ingress-nginx/install.sh \
  --cluster kind-dev-cluster \
  --dry-run  # Preview first

./eks/addons/ingress-nginx/install.sh \
  --cluster kind-dev-cluster
```

### Step 4: Verify the Installation

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

## Option 2: AWS EKS

### Step 1: Configure AWS

```bash
aws configure
aws sts get-caller-identity
```

### Step 2: Connect to EKS Cluster

```bash
aws eks update-kubeconfig --name my-eks-cluster --region us-west-2
kubectl get nodes
```

### Step 3: Install Addons

```bash
# Preview changes
./eks/addons/aws-load-balancer-controller/install.sh \
  --cluster my-eks-cluster \
  --dry-run

# Install
./eks/addons/aws-load-balancer-controller/install.sh \
  --cluster my-eks-cluster
```

## Common Commands

### List Available Addons

```bash
ls eks/addons/
```

### Get Addon Help

```bash
./eks/addons/<addon-name>/install.sh --help
```

### Uninstall Addon

```bash
./eks/addons/<addon-name>/uninstall.sh --cluster <cluster-name>
```

### Deploy a Scenario

```bash
# Scenarios install multiple addons in order
./eks/scenarios/api-gateway/deploy.sh \
  --cluster <cluster-name> \
  --dry-run
```

## Next Steps

- [Architecture Overview](architecture/OVERVIEW.md)
- [Addon Development Guide](guides/ADDON_DEVELOPMENT.md)
- [Troubleshooting Guide](guides/TROUBLESHOOTING.md)
- [Contributing Guidelines](../CONTRIBUTING.md)

## Getting Help

```bash
# Script help
./eks/addons/<addon>/install.sh --help

# Check tool versions
make check-versions

# Run linters
make lint

# Run tests
make test
```

---

*Last updated: 2026-01-31*
