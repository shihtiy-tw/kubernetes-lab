---
id: spec-014
title: Configuration Examples & Templates
type: enhancement
priority: medium
status: planned
assignable: true
estimated_hours: 12
tags: [configuration, examples, templates]
---

# Configuration Examples & Templates for kubernetes-lab

## Overview
Create comprehensive configuration examples for various deployment scenarios.

## Tasks

### Spec 014: P1/US1 Example Configurations
### Spec 014: P2/US2 Configuration Validation
### Spec 014: P3/US3 Deployment Patterns

- [ ] Create blue-green deployment example
- [ ] Write canary deployment example
- [ ] Create rolling update example
- [ ] Write GitOps deployment example
- [ ] Create A/B testing deployment example

## Directory Structure
```
examples/
├── addons/
│   ├── ingress-nginx/
│   │   ├── basic/
│   │   ├── ha/
│   │   └── multi-region/
│   └── karpenter/
│       ├── basic/
│       ├── spot-instances/
│       └── gpu-nodes/
├── scenarios/
│   ├── development/
│   ├── staging/
│   └── production/
└── overlays/
    ├── dev/
    ├── staging/
    └── prod/
```

## Example Templates

### Helm Values Template
```yaml
# examples/addons/ingress-nginx/ha/values.yaml
controller:
  replicaCount: 3
  
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 1000m
      memory: 512Mi
  
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 80
  
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          topologyKey: topology.kubernetes.io/zone
```

### Environment Template
```bash
# .env.example
# EKS Cluster Configuration
CLUSTER_NAME=my-eks-cluster
AWS_REGION=us-west-2
K8S_VERSION=1.28

# Addon Versions
INGRESS_NGINX_VERSION=4.8.0
KARPENTER_VERSION=0.32.0
```

### Kustomization Overlay
```yaml
# examples/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

resources:
  - ../../base

patches:
  - path: replica-count.yaml
    target:
      kind: Deployment

replicas:
  - name: app
    count: 5

configMapGenerator:
  - name: app-config
    env: config.env
```

## Acceptance Criteria
- All examples are tested and validated
- Configuration files include comments
- JSON Schemas are comprehensive
- Documentation explains each example
- Examples cover common use cases

## Dependencies
- None

## Notes
- Use realistic values in examples
- Include cost estimates in comments
- Document trade-offs for each configuration
- Provide migration paths between configs
