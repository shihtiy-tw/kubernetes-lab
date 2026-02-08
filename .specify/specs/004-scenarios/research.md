# Spec 004: Scenarios & Testing

## Overview
This spec defines a standardized library of "Scenarios" - self-contained, verifiable usage patterns for Kubernetes resources.

## Scenario Categories

### 1. General (Platform-Agnostic)
These work on Kind, EKS, GKE, and AKS identically.

| Scenario | Description |
|---|---|
| **pod-basic** | Simple Nginx pod lifecycle |
| **deployment-rolling** | Deployment with rolling update strategy |
| **service-clusterip** | Internal service discovery via DNS |
| **service-nodeport** | External access via NodePort |
| **ingress-nginx** | Ingress routing via Nginx controller |
| **configmap-volume** | Mount ConfigMap as volume |
| **secret-env** | Inject Secret as environment variable |
| **job-cronjob** | Batch processing jobs |
| **statefulset-pvc** | Stateful app with PersistentVolumeClaim |
| **daemonset-fluentd** | Log collector pattern |
| **hpa-cpu** | Horizontal Pod Autoscaling on CPU |
| **pdb-disruption** | Pod Disruption Budget enforcement |

---

### 2. CSP-Specific (Platform Integration)

#### AWS (EKS)
| Scenario | Description |
|---|---|
| **eks-irsa-s3** | Pod accessing S3 via IAM Roles for Service Accounts |
| **eks-alb-ingress** | Ingress using AWS Application Load Balancer |
| **eks-nlb-service** | Service using AWS Network Load Balancer |
| **eks-ebs-retain** | PVC using EBS gp3 with Retain policy |
| **eks-efs-shared** | ReadWriteMany PVC using EFS |
| **eks-fargate** | Pod scheduling on Fargate profile |

#### GCP (GKE)
| Scenario | Description |
|---|---|
| **gke-workload-id** | Pod accessing GCS via Workload Identity |
| **gke-neg-ingress** | Ingress using Google Cloud Load Balancer (NEG) |
| **gke-ilb-service** | Internal Load Balancer service |
| **gke-pd-balanced** | PVC using pd-balanced storage class |
| **gke-filestore** | ReadWriteMany PVC using Filestore |
| **gke-cloud-armor** | Ingress protected by Cloud Armor policy |

#### Azure (AKS)
| Scenario | Description |
|---|---|
| **aks-workload-id** | Pod accessing KeyVault via Workload Identity |
| **aks-appgw** | Ingress using Application Gateway |
| **aks-azure-disk** | PVC using Azure Disk (LRS) |
| **aks-azure-file** | ReadWriteMany PVC using Azure Files |
| **aks-private-link** | Private access to Azure PaaS services |

---

## Testing Strategy (KUTTL)
Each scenario must include a `kuttl-test.yaml` verifying:
1. Resource creation (Assert file)
2. Status readiness (Wait conditions)
3. Functionality check (e.g., `curl` endpoint, check logs)
