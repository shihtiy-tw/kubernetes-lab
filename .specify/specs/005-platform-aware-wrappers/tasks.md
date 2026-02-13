# Tasks: Platform-Aware Wrapper Scripts

Implementation steps for unified CLI wrappers in `scripts/`.

## Phase 1: Foundation & Utilities

- [x] **Task 1.1**: Create shared logging and color utility `scripts/utils/common.sh`.
  - Pattern: Extract from `eks/utils/setup-cluster.sh`.
  - Include: `log_info`, `log_error`, `log_warn`, `log_step`, and `check_binary`.
- [x] **Task 1.2**: Implement `scripts/utils/validate-platform.sh`.
  - Validate `--platform` against `[kind, eks, gke, aks]`.
  - Validate required binary presence (e.g., `eksctl` for EKS).

## Phase 2: Cluster Lifecycle Wrappers

- [x] **Task 2.1**: Implement `scripts/k8s.cluster.create.sh`.
  - Dispatcher logic with flag mapping (`--region`, `--version`, `--config`).
  - Implement naming convention `{platform}-{version}-{config}-{name}`.
  - Forward remaining args via array.
- [x] **Task 2.2**: Implement `scripts/k8s.cluster.delete.sh`.
  - Add confirmation prompt for destructive action.
  - Support `--yes`/`--force` for non-interactive bypass.

## Phase 3: Operational Wrappers

- [x] **Task 3.1**: Implement `scripts/k8s.addon.install.sh`.
  - Map generic flags to platform-specific addon scripts.
- [x] **Task 3.2**: Implement `scripts/k8s.logs.sh`.
  - Wrap `kubectl logs` with context switching.
- [x] **Task 3.3**: Implement `scripts/k8s.scenario.run.sh`.
  - Dispatch to platform scenario deployments.

## Phase 4: Validation & Quality

- [x] **Task 4.1**: Add `--help` and `--version` to all wrappers.
- [x] **Task 4.2**: Implement basic BATS tests for flag mapping logic in `tests/wrappers/`.
- [x] **Task 4.3**: Verify all wrappers follow the Project Constitution (12-factor CLI).
