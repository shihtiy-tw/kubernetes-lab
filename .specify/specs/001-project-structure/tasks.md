# Tasks: Project Structure & Organization

**Input**: Design documents from `.specify/specs/001-project-structure/`
**Prerequisites**: plan.md (required), spec.md (required)

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Initialize repository structure based on Spec 001 definitions
- [ ] T002 [P] Create missing platform directories in kubernetes-lab/ (eks, gke, aks, kind)
- [ ] T003 [P] Create missing support directories in kubernetes-lab/ (docs, scripts, shared, tests)

## Phase 2: Foundational (Blocking Prerequisites)

- [ ] T004 [P] Create architecture.md in kubernetes-lab/docs/
- [ ] T005 [P] Move existing AGENTS.md to kubernetes-lab/ if not already present
- [ ] T006 [P] Ensure Makefile exists with standard targets

## Phase 3: User Story 1 - Immutable Top-Level Structure (Priority: P1)

**Goal**: Enforce the monorepo structure to ensure consistency across cloud providers

- [ ] T007 [US1] Audit root directory for non-compliant files/folders in kubernetes-lab/
- [ ] T008 [US1] Move loose scripts to kubernetes-lab/scripts/
- [ ] T009 [US1] Organize kubernetes-lab/shared/ into charts, manifests, plugins, and scenarios
- [ ] T010 [US1] Verify platform directories (eks, gke, aks, kind) follow Spec 002 standards

## Phase 4: Polish & Cross-Cutting Concerns

- [ ] T011 [P] Create scripts/validate-structure.sh to verify adherence to Spec 001
- [ ] T012 Add 'make check-structure' target to kubernetes-lab/Makefile
- [ ] T013 [P] Update kubernetes-lab/README.md with new structure details
