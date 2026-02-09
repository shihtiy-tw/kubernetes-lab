# Kubernetes Lab Scenarios

This directory contains categorized Kubernetes scenarios for troubleshooting, testing, and demonstration purposes.

## Scenario Categories

| Category | Description |
|----------|-------------|
| [general/](./general/) | Basic Kubernetes resources and generic patterns |
| [eks/](./eks/) | AWS-specific scenarios and integrations |
| [gke/](./gke/) | Google Cloud-specific scenarios and integrations |
| [aks/](./aks/) | Azure-specific scenarios and integrations |
| [network/](./network/) | Advanced networking patterns (Cilium, Calico, etc.) |

## Scenario Structure

Each scenario follows a standardized structure:

```
scenario-name/
├── README.md           # Scenario documentation
├── manifests/          # Kubernetes YAML files
└── kuttl-test.yaml     # Automated verification (KUTTL)
```

## Running Scenarios

Most scenarios can be applied directly using `kubectl`:

```bash
kubectl apply -f <category>/<scenario-name>/manifests/
```

For platform-specific scenarios (EKS, AKS, GKE), check the category-specific README for deployment scripts or requirements.

## Automated Verification

We use [KUTTL](https://kuttl.dev/) to verify that scenarios are working as expected:

```bash
kubectl kuttl test --config <category>/<scenario-name>/kuttl-test.yaml
```
