---
id: spec-001
title: Project Structure & Organization
type: standard
priority: critical
status: proposed
tags: [governance, structure, architecture]
---

# Spec 001: Project Structure & Organization

## Overview
This specification defines the immutable top-level structure of the `kubernetes-lab` monorepo.Adherence to this structure is mandatory to ensure consistency across multiple cloud provider implementations and to support the platform-aware command system.

## Root Directory Layout

```text
kubernetes-lab/
├── .opencode/          # Agent commmands and tools
├── .specify/           # Specs, plans, and reports
├── .github/            # GitHub Actions workflows
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

## detailed Definitions

### Platform Directories (`eks/`, `gke/`, `aks/`, `kind/`)
Each platform directory MUST be self-contained and follow **Spec 002**. No platform code shall exist outside its designated directory, except for truly shared logic in `shared/`.

### Shared Resources (`shared/`)
Contains resources that are platform-agnostic.
- `charts/`: Local Helm charts.
- `manifests/`: Raw Kubernetes YAMLs (e.g., standard nginx deployment).
- `plugins/`: Scripts capable of running on any cluster (e.g., `install-argocd.sh` that checks `kubectl` context).
- `scenarios/`: High-level scenarios that run on any certified K8s cluster (e.g., `game-2048`).

### Documentation (`docs/`)
Contains architectural decisions, diagrams, and deep-dive explanations.
- `architecture.md`: System design.
- `governance/`: Policy documents.

### Automation (`scripts/` & `Makefile`)
- `scripts/` contains dev-loop utilities (e.g., `lint.sh`, `test-all.sh`).
- `Makefile` provides a standard entry point for humans (`make lint`, `make test`).

## Governance Files
- `AGENTS.md`: The single source of truth for agent context. MUST be updated when structure changes.
- `.specify/`: Contains all `spec-*.md` files.

## Compliance
- **No new top-level directories** without a revision to this spec.
- All "loose" files must be categorized into one of the above directories.
