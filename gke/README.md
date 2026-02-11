# GKE (Google Kubernetes Engine)

**Status**: 🟢 Implementation in Progress  
**Platform**: Google Cloud Platform  
**CLI**: `gcloud`

---

## Prerequisites

1. **Google Cloud SDK** installed and configured
   ```bash
   # Install: https://cloud.google.com/sdk/docs/install
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **kubectl** installed
   ```bash
   gcloud components install kubectl
   ```

3. **Helm** (for addons)
   ```bash
   # https://helm.sh/docs/intro/install/
   ```

4. **Required APIs** enabled
   ```bash
   gcloud services enable container.googleapis.com \
                          compute.googleapis.com \
                          iam.googleapis.com \
                          cloudresourcemanager.googleapis.com \
                          dns.googleapis.com
   ```

5. **gke-gcloud-auth-plugin** (for Kubernetes 1.26+)
   ```bash
   gcloud components install gke-gcloud-auth-plugin
   ```

---

## Quick Start

### Create a Cluster

```bash
# Regional cluster (recommended for production)
./clusters/gke-cluster-create.sh \
    --name my-cluster \
    --region us-central1 \
    --node-count 2

# Zonal cluster (cheaper for dev)
./clusters/gke-cluster-create.sh \
    --name dev-cluster \
    --zone us-central1-a \
    --node-count 1

# See all options
./clusters/gke-cluster-create.sh --help
```

### Add Node Pool

```bash
./nodegroups/gke-nodepool-create.sh \
    --name spot-pool \
    --cluster my-cluster \
    --region us-central1 \
    --spot \
    --min-nodes 0 \
    --max-nodes 5
```

### Install Addons

```bash
# Ingress NGINX
./addons/ingress-nginx/install.sh

# Workload Identity
./addons/workload-identity/install.sh \
    --k8s-namespace my-app \
    --k8s-sa my-app-sa \
    --gcp-sa my-app@project.iam.gserviceaccount.com
```

### Delete Cluster

```bash
./clusters/gke-cluster-delete.sh \
    --name my-cluster \
    --region us-central1
```

---

## Directory Structure

```
gke/
├── addons/                 # GKE-specific addons
│   ├── ingress-nginx/      # Ingress controller
│   └── workload-identity/  # GCP service account binding
├── clusters/               # Cluster lifecycle scripts
│   ├── gke-cluster-create.sh
│   └── gke-cluster-delete.sh
├── nodegroups/             # Node pool management
│   └── gke-nodepool-create.sh
├── scenarios/              # Usage examples (WIP)
├── tests/                  # Integration tests (WIP)
└── utils/                  # Helper functions
```

---

## Cost Warning

> ⚠️ **GKE incurs real costs!** Always delete clusters when not in use.

**Estimated costs** (us-central1, as of 2024):
- Regional cluster: ~$0.10/hour (management fee)
- e2-medium node: ~$0.03/hour

**Cost optimization tips**:
1. Use `--zone` instead of `--region` for dev clusters
2. Use `--spot` for interruptible workloads
3. Enable autoscaling with `--min-nodes 0`

---

## Troubleshooting

### Cannot create cluster
```bash
# Check quotas
gcloud compute regions describe us-central1 --format="table(quotas)"

# Check API enabled
gcloud services list --enabled | grep container
```

### Authentication issues
```bash
gcloud auth login
gcloud container clusters get-credentials CLUSTER_NAME --region REGION
```

### Node pool not scaling
```bash
# Check autoscaler status
kubectl describe configmap cluster-autoscaler-status -n kube-system
```

---

## See Also

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
