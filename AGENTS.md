# kubernetes-lab Agent Context

**Domain**: Kubernetes across multiple cloud providers  
**Location**: `/home/yst/Labs/kubernetes-lab`  
**Type**: Monorepo (EKS, GKE, AKS)

---

## Current Focus

> 🎯 **EKS → Migrating content from eks-lab**

---

## YOU ARE HERE

```
kubernetes-lab/
├── kind/ ← 🟢 LOCAL TESTING
├── eks/ ← 🔵 ACTIVE (migrated)
│   ├── addons/
│   ├── clusters/
│   ├── scenarios/
│   └── ...
├── gke/ (placeholder)
└── aks/ (placeholder)
```

---

## Structure

| Directory | Purpose |
|-----------|---------|
| `shared/` | Cross-platform plugins, manifests, charts |
| `kind/` | Local testing with kind clusters |
| `eks/` | AWS EKS implementation |
| `gke/` | Google GKE implementation |
| `aks/` | Azure AKS implementation |

Each implementation has:
- `addons/` - Platform-specific add-ons
- `clusters/` - Cluster definitions
- `nodegroups/` - Node group configs
- `scenarios/` - Usage patterns
- `tests/` - Integration tests (KUTTL)
- `utils/` - Helper utilities

---

## Quick Start

```bash
# EKS scenario
cd eks/scenarios/load-balancers
./deploy.sh --cluster my-cluster

# Shared plugin
cd shared/plugins/ingress-nginx
./install.sh --help
```

---

## Lab Sessions

| Date | Focus | Notes |
|------|-------|-------|
| 2026-01-30 | Initial setup | Migrating from eks-lab |

---

## Context Sources

- `.specify/` - Speckit specs and plans
- `shared/` - Reusable across implementations
- Each `*/README.md` - Implementation-specific context

---

## 12-Factor Compliance

- **CLI**: All scripts have --help, --version, flags
- **Agents**: Context in AGENTS.md per implementation
- **Testing**: KUTTL integration tests

---

## Commands

See: `.opencode/command/*.md` for full command documentation

### Speckit (Spec-Driven Workflow)
- `speckit.specify` - Create new specifications
- `speckit.plan` - Create implementation plans
- `speckit.tasks` - Generate task lists
- `speckit.implement` - Execute implementation

### Kubernetes Operations (Platform-Aware)
```bash
# Cluster lifecycle (--platform: kind|eks|gke|aks)
k8s.cluster.create --platform kind --name dev-local
k8s.cluster.delete --platform eks --name prod-cluster

# Addon management
k8s.addon.install --platform eks --addon ingress-nginx --cluster prod

# Scenario deployment
k8s.scenario.run --platform gke --scenario load-balancers --cluster staging

# Testing and validation
k8s.test.integration --platform kind --cluster dev-local
k8s.manifest.validate --platform eks --path eks/scenarios/

# Debugging
k8s.logs --platform aks --cluster test --deployment nginx
```
