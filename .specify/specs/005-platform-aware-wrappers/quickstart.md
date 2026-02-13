# Quickstart: Platform-Aware Wrapper Scripts

Learn how to use the unified `k8s.*` wrapper scripts to manage Kubernetes clusters from the repository root.

## Cluster Management

### Create a Cluster
Use `k8s.cluster.create.sh` with the `--platform` flag. The scripts automatically handle platform-specific flag mapping and naming conventions (`{platform}-{version}-{config}-{name}`).

```bash
# Create a Kind cluster with default settings
./scripts/k8s.cluster.create.sh --platform kind --name dev

# Create an EKS cluster with specific version and region
./scripts/k8s.cluster.create.sh --platform eks --name lab --version 1.29 --region us-west-2

# Create a GKE cluster with a specific project
./scripts/k8s.cluster.create.sh --platform gke --name test --project my-gcp-project
```

### Delete a Cluster
Use `k8s.cluster.delete.sh`. Deletion will prompt for confirmation unless `--yes` or `--force` is used.

```bash
# Delete the EKS cluster with confirmation
./scripts/k8s.cluster.delete.sh --platform eks --name lab

# Force delete without confirmation (CI/CD)
./scripts/k8s.cluster.delete.sh --platform kind --name dev --yes
```

## Addon Management

### Install an Addon
Use `k8s.addon.install.sh`. The script automatically handles platform-specific configuration and Helm values.

```bash
# Install ingress-nginx on EKS
./scripts/k8s.addon.install.sh --platform eks --addon ingress-nginx --cluster eks-1-29-standard-lab

# Install Metrics Server on Kind
./scripts/k8s.addon.install.sh --platform kind --addon metrics-server --cluster kind-latest-standard-dev
```

## Logs and Observability

### Retrieve Pod Logs
Use `k8s.logs.sh` for unified log retrieval with automatic context switching.

```bash
# Get logs from a deployment in an AKS cluster
./scripts/k8s.logs.sh --platform aks --cluster aks-1-29-standard-test --deployment nginx
```

## Scenario Deployment

### Deploy full Lab Scenarios
Use `k8s.scenario.run.sh` to deploy full scenarios across any platform.

```bash
# Deploy the "load-balancers" scenario on GKE
./scripts/k8s.scenario.run.sh --platform gke --scenario load-balancers --cluster gke-1-29-standard-prod
```

## Global Environment Variables
You can set default values to reduce flag usage:

```bash
export K8S_PLATFORM="eks"
export AWS_REGION="us-west-2"

# Now you can just run:
./scripts/k8s.cluster.create.sh --name auto-default
```

## Dry-Run Mode
All scripts support `--dry-run` to see what command would be executed without making changes.

```bash
./scripts/k8s.cluster.create.sh --platform aks --name test --dry-run
# Output: [DRY RUN] Would execute: ./aks/clusters/create.sh --name aks-latest-standard-test --resource-group aks-latest-standard-test --location eastus
```
