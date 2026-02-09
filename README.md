# 🏗️ Project Spec: High-Speed Multi-Cloud K8s Lab Engine

> [!bot] **InboxClaw Integrated Capture**
> **Source**: Combined discussions from 2026-02-02 and 2026-02-03.
> **Status**: Ready for Implementation.
> **Priority**: ⏫ High (Strategic Support Asset)

## 🎯 The Vision
Build a standardized, test-driven Kubernetes Lab framework that can be deployed instantly across **AWS (EKS), Azure (AKS), GCP (GKE), and Kind**. The goal is to eliminate the latency of "starting from zero" when reproducing customer environments for support troubleshooting.

---

## 🧱 Core Component Matrix
For every scenario, the engine must define equivalent resources for:

1.  **Compute Workloads**: `Pod`, `ReplicaSet`, `Deployment`, `DaemonSet`, `StatefulSet`.
2.  **Network Architecture**: `Service`, `Ingress`, `API Gateway`.
3.  **Infrastructure Abstraction**: 
    - **CNI**: (e.g., AWS VPC CNI vs. Calico vs. Azure CNI).
    - **CSI**: (e.g., EBS vs. Managed Disk vs. Local Storage).
4.  **Operational Addons**:
    - **Observability**: Monitoring (Prometheus/Grafana) & Observability stack.
    - **Scaling**: Scalability configurations (HPA/VPA).
    - **Security**: Network Policies, OPA/Gatekeeper, and other security addons.

---

## 📅 Execution Log & Next Actions
- **2026-02-02**: Initial vision and component list defined.
- **2026-02-03**: Integrated "Master Prompt" and "10-minute" constraint.

---
*Mantra: Synthesize to simplify, execute to conquer.*
