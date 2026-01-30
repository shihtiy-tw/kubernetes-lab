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

See: `.opencode/commands/*.md` for lab management
