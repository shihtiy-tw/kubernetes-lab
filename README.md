---
append_modified_update: true
category: effort
type: project
status: Cultivation
priority: 02high
domain: "[[Atlas/Index/Domains/202109072212_README_CSIE|CSIE]]"
start: 2026-02-02
due: 2026-03-02
kind: horizon
author: agent
created: 2026-02-03T20:00:00
dateModified: 2026-02-11T00:00:00
modified:
  - 2026-02-11T00:00:00
---

# 🏗️ Project Spec: High-Speed Multi-Cloud K8s Lab Engine

> [!bot] **InboxClaw Integrated Capture**
> **Source**: Combined discussions from 2026-02-02 and 2026-02-03.
> **Status**: Ready for Antigravity Implementation.
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

## 📂 Project Structure

Adherence to this structure is mandatory (see **Spec 001**).

```text
kubernetes-lab/
├── aks/                # Azure Kubernetes Service implementation
├── docs/               # Architecture and design documentation
├── eks/                # Amazon Elastic Kubernetes Service implementation
├── gke/                # Google Kubernetes Engine implementation
├── kind/               # Local Kind cluster implementation
├── scripts/            # Repository-level utility scripts (linting, setup)
├── shared/             # Cross-platform resources (Helm charts, manifests)
├── tests/              # Cross-platform integration tests (KUTTL)
├── AGENTS.md           # Master context file for AI agents
├── BACKLOG.md          # Future work and idea parking lot
├── Makefile            # Standard build targets
└── README.md           # Entry point documentation
```

---

## ⚙️ Implementation Strategy
 (Antigravity Master Prompt)

Use this prompt to task Antigravity with generating specific lab scenarios:

> "You are acting as a **Senior Cloud Solutions Architect & DevOps Expert**. Your mission is to implement a high-speed, cross-cloud Kubernetes Lab framework for rapid customer reproduction.
>
> ### 🧩 Requirements:
> - **Environment Mapping**: Provide a comparison table of equivalent services across AWS, Azure, GCP, and Kind.
> - **Manifest Templates**: Generate ready-to-apply YAML files for the target cloud.
> - **Automated Validation**: Include a `verify.sh` script (kubectl/pytest) to ensure all components are healthy.
> - **Speed Optimization**: Instructions must ensure the environment is live in **< 10 minutes**.
>
> ### 🔬 Scenario Target: 
> [INSERT SCENARIO HERE, e.g., 'Internal Microservice with API Gateway and Managed Storage']"

---

## 📅 Execution Log & Next Actions
- **2026-02-02**: Initial vision and component list defined.
- **2026-02-03**: Integrated "Master Prompt" and "10-minute" constraint.
- [ ] **Next Step**: Choose the first specific scenario to prototype during the Tuesday 11:00 session.
- [ ] **Future**: Fork and enhance Wiz Demo repo to complement this lab.

---
*Mantra: Synthesize to simplify, execute to conquer.*
