# kubernetes-lab Constitution

## Core Principles

### I. Cloud-Agnostic First
- Extract common patterns to `shared/`
- Use Kustomize overlays for cloud-specific customization
- Test with Kind before cloud deployment
- Production-oriented examples with security and cost considerations

### II. CLI 12-Factor Compliance
Every script must:
1. **Help Always Works**: `--help` flag with usage info
2. **Flags Over Prompts**: Non-interactive by default
3. **Version Command**: `--version` reports version
4. **Stdout/Stderr**: Success → stdout, errors → stderr
5. **Exit Codes**: 0=success, 1=user error, 2=system error
6. **Dry Run**: `--dry-run` for preview when applicable
7. **Idempotent**: Safe to run multiple times

### III. Test-First Strategy
- All shared plugins tested locally with Kind first
- KUTTL for declarative Kubernetes tests
- Smoke tests for quick validation
- Cloud tests with cost awareness (cleanup after)

### IV. Progressive Complexity
- Start simple, add complexity gradually
- Each scenario builds on previous knowledge
- Clear prerequisites documented
- Learning objectives in every scenario

### V. Agent 12-Factor
1. **Own Prompts**: AGENTS.md per directory
2. **Explicit Tools**: Document available skills
3. **Context Boundaries**: Clear scope
4. **Human Contact**: Ask before destructive ops

## Structure Standards

```
{implementation}/
├── addons/      # Platform-specific add-ons
├── clusters/    # Cluster configurations
├── nodegroups/  # Node group definitions
├── scenarios/   # Usage patterns
├── tests/       # Integration tests
└── utils/       # Helper scripts
```

## Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_VERSION="1.0.0"
show_help() { ... }
show_version() { echo "$(basename "$0") version ${SCRIPT_VERSION}"; }
log_info() { echo "[INFO] $*" >&1; }
log_error() { echo "[ERROR] $*" >&2; }

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -v|--version) show_version; exit 0 ;;
        ...
    esac
done
```

## Documentation Standards

Every scenario includes:
1. README.md with purpose, prerequisites, usage
2. What You'll Learn section
3. Quick Start copy-paste commands
4. Cleanup instructions

## Commit Conventions

```
feat(eks/scenarios): add GPU workload example
fix(shared/plugins): correct cert-manager namespace
docs(kind): add multi-node setup guide
refactor(gke): CLI 12-factor compliance
test(eks): add KUTTL tests for load-balancer
```

## Governance

- Constitution supersedes all other practices
- All scripts must pass `--help` verification
- Kind testing required before cloud deployment
- Cost cleanup required for cloud resources

**Version**: 1.0.0 | **Ratified**: 2026-01-30 | **Last Amended**: 2026-01-30
