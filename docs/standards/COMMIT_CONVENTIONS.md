# Commit Message Conventions

This project follows [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

## Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat` | New feature | Minor |
| `fix` | Bug fix | Patch |
| `docs` | Documentation only | None |
| `style` | Formatting, no code change | None |
| `refactor` | Code change, no feature/fix | None |
| `perf` | Performance improvement | Patch |
| `test` | Adding/updating tests | None |
| `chore` | Maintenance tasks | None |
| `ci` | CI/CD changes | None |
| `build` | Build system changes | None |
| `revert` | Revert previous commit | Varies |

## Scopes

Use these scopes for kubernetes-lab:

| Scope | Description |
|-------|-------------|
| `addons` | EKS addon scripts |
| `scenarios` | Deployment scenarios |
| `kind` | Kind cluster scripts |
| `eks` | EKS-specific changes |
| `gke` | GKE-specific changes |
| `aks` | AKS-specific changes |
| `shared` | Shared utilities |
| `tests` | Test files |
| `docs` | Documentation |
| `ci` | CI/CD pipelines |
| `deps` | Dependencies |
| `config` | Configuration files |

## Examples

### Features

```bash
# Simple feature
feat(addons): add karpenter support

# Feature with body
feat(scenarios): add high-availability scenario

Implements a multi-AZ deployment with:
- 3 node groups across availability zones
- Pod disruption budgets
- Topology spread constraints

Closes #42
```

### Bug Fixes

```bash
# Simple fix
fix(addons): correct ingress-nginx namespace

# Fix with details
fix(eks): resolve security group timeout issue

The security group rules were being applied before the
VPC endpoints were fully available, causing timeouts.

Added retry logic with exponential backoff.

Fixes #123
```

### Documentation

```bash
docs(readme): update installation instructions

docs(addons): add karpenter configuration guide

docs: add architecture diagram using mermaid
```

### Refactoring

```bash
refactor(addons): apply CLI 12-factor compliance

Update all addon scripts to follow CLI 12-factor principles:
- Add --help and --version flags
- Convert positional args to flags
- Add --dry-run support
- Implement proper exit codes
```

### Chores

```bash
chore(deps): update helm chart versions

chore: update pre-commit hooks

chore(ci): add shellcheck to lint workflow
```

### Breaking Changes

```bash
# Breaking change (append ! after type or use BREAKING CHANGE footer)
feat(addons)!: change default values format

BREAKING CHANGE: Values files now use new schema.
Migrate existing values files using ./scripts/migrate-values.sh
```

## Rules

1. **Subject line**:
   - Use imperative mood ("add" not "added")
   - Max 50 characters
   - No period at end
   - Lowercase first letter

2. **Body**:
   - Wrap at 72 characters
   - Explain what and why, not how
   - Separate from subject with blank line

3. **Footer**:
   - Reference issues: `Closes #123`, `Fixes #456`
   - Breaking changes: `BREAKING CHANGE: description`
   - Co-authors: `Co-authored-by: Name <email>`

## Git Configuration

### Commit Template

Create `.gitmessage` in your home directory:

```bash
# Set up commit template
git config --global commit.template ~/.gitmessage
```

### Pre-commit Hook

This project uses commitizen for commit message validation.
See `.pre-commit-config.yaml` for configuration.

## Quick Reference

```bash
# Feature
git commit -m "feat(addons): add prometheus-stack"

# Bug fix
git commit -m "fix(eks): resolve cluster creation race condition"

# Documentation
git commit -m "docs(readme): add troubleshooting section"

# Refactoring
git commit -m "refactor(shared): extract common functions"

# Tests
git commit -m "test(addons): add bats tests for ingress-nginx"

# Chore
git commit -m "chore(deps): bump helm-secrets to v4.5.0"

# CI
git commit -m "ci(github): add security scanning workflow"

# Breaking change
git commit -m "feat(addons)!: require explicit namespace flag"
```

---

*Last updated: 2026-01-31*
