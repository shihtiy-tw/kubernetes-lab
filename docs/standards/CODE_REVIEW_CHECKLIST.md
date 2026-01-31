# Code Review Checklist

Use this checklist when reviewing Pull Requests for kubernetes-lab.

## Quick Checks

- [ ] PR has a clear description
- [ ] Changes are focused and not too large
- [ ] All CI checks pass
- [ ] No merge conflicts

---

## Shell Scripts

### CLI 12-Factor Compliance

- [ ] Has `--help` flag that displays usage
- [ ] Has `--version` flag
- [ ] Uses flag-based arguments (no positional args)
- [ ] Has `--dry-run` support where applicable
- [ ] Returns proper exit codes (0 success, 1 error)
- [ ] Outputs logs to stderr, results to stdout

### Code Quality

- [ ] Starts with `#!/usr/bin/env bash`
- [ ] Uses `set -euo pipefail`
- [ ] Has cleanup trap registered
- [ ] Validates required variables early
- [ ] Uses functions for reusable logic
- [ ] Functions are documented with comments
- [ ] No hardcoded paths or values

### Error Handling

- [ ] Returns appropriate exit codes
- [ ] Error messages include context
- [ ] Error messages suggest remediation
- [ ] Cleanup runs on failure

### Security

- [ ] No hardcoded credentials
- [ ] No sensitive data in logs
- [ ] Validates external inputs
- [ ] Uses quotes around variables

---

## YAML Files

### Kubernetes Manifests

- [ ] Uses proper apiVersion and kind
- [ ] Includes standard labels (`app.kubernetes.io/*`)
- [ ] Specifies namespaces explicitly
- [ ] Resource limits are set
- [ ] Security contexts are defined

### Helm Values

- [ ] Comments explain each section
- [ ] Sensible defaults provided
- [ ] Follows existing value structure

### Configuration

- [ ] Valid YAML syntax
- [ ] Consistent indentation (2 spaces)
- [ ] No trailing whitespace

---

## Documentation

### README Updates

- [ ] Installation instructions are clear
- [ ] Configuration options documented
- [ ] Examples provided
- [ ] Troubleshooting section if needed

### Code Comments

- [ ] Complex logic is explained
- [ ] WHY not just WHAT
- [ ] Function headers present

### New Features

- [ ] README updated
- [ ] Changelog entry added (if applicable)
- [ ] Example usage shown

---

## Testing

### Test Coverage

- [ ] New features have tests
- [ ] Test names are descriptive
- [ ] Tests cover happy and error paths

### Manual Testing

- [ ] Works on fresh cluster
- [ ] Uninstall is clean
- [ ] Dry-run works correctly

---

## Performance & Best Practices

### Efficiency

- [ ] No unnecessary API calls
- [ ] Uses caching where appropriate
- [ ] Timeouts are reasonable
- [ ] Retry logic is sensible

### Maintainability

- [ ] Code is modular
- [ ] DRY principles followed
- [ ] Consistent with existing patterns

---

## Merge Requirements

Before approving:

- [ ] All CI checks pass
- [ ] At least one approving review
- [ ] No unresolved conversations
- [ ] Branch is up to date with main
- [ ] All checklist items above satisfied

---

## Review Notes Template

```markdown
## Review Summary

### ✅ Approved / ⚠️ Changes Requested / ❓ Questions

### What I Reviewed
- 

### Findings
- 

### Suggestions (Non-blocking)
- 

### Required Changes (Blocking)
- 
```

---

*Last updated: 2026-01-31*
