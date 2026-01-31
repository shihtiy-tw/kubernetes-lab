# Release Checklist

Checklist for preparing a kubernetes-lab release.

## Pre-Release

### Version

- [ ] Version number determined (semantic versioning)
- [ ] CHANGELOG.md updated
- [ ] Version bumped in relevant files

### Code Quality

- [ ] All tests pass
- [ ] Linting passes (`pre-commit run --all-files`)
- [ ] No TODO/FIXME items for this release
- [ ] Dependencies are up to date

### Documentation

- [ ] README is current
- [ ] All new features documented
- [ ] Breaking changes documented
- [ ] Migration guide written (if breaking changes)
- [ ] API/CLI documentation updated

### Security

- [ ] Security scan completed
- [ ] No critical vulnerabilities
- [ ] Secrets scan passed
- [ ] Dependencies audited

---

## Testing

### Functional Testing

- [ ] All addons install successfully
- [ ] All addons uninstall cleanly
- [ ] All scenarios deploy correctly
- [ ] Dry-run mode works

### Environment Testing

- [ ] Tested on EKS (primary target)
- [ ] Tested on Kind (local development)
- [ ] Tested with latest Kubernetes version
- [ ] Tested with oldest supported Kubernetes version

### Integration Testing

- [ ] Addon combinations tested
- [ ] Scenario workflows tested
- [ ] CI/CD integration tested

---

## Release Preparation

### Git

- [ ] Main branch is clean
- [ ] All PRs merged
- [ ] No pending reviews
- [ ] Branch protection verified

### Changelog

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- 

### Changed
- 

### Deprecated
- 

### Removed
- 

### Fixed
- 

### Security
- 
```

### Release Notes

- [ ] Summary of key changes
- [ ] Upgrade instructions
- [ ] Known issues listed
- [ ] Contributors acknowledged

---

## Release Process

### Create Release

```bash
# Ensure on main and up to date
git checkout main
git pull origin main

# Create tag
git tag -a v1.2.3 -m "Release v1.2.3"

# Push tag
git push origin v1.2.3
```

### GitHub Release

- [ ] Create GitHub release from tag
- [ ] Copy release notes
- [ ] Attach any artifacts
- [ ] Mark as pre-release if applicable

### Announcements

- [ ] Update project status/README badges
- [ ] Notify stakeholders
- [ ] Update documentation site (if separate)

---

## Post-Release

### Verification

- [ ] Release artifacts are accessible
- [ ] Installation from release works
- [ ] Documentation links work
- [ ] No immediate issues reported

### Cleanup

- [ ] Close milestone
- [ ] Archive completed issues
- [ ] Update roadmap

### Next Version

- [ ] Start new CHANGELOG section
- [ ] Create milestone for next version
- [ ] Triage backlog for next version

---

## Rollback Procedure

If critical issues are found:

1. **Assess Impact**
   - How many users affected?
   - Is there a workaround?
   - Severity of the issue?

2. **Quick Fix vs Rollback**
   - Can issue be fixed with patch release?
   - Is rollback safer?

3. **Rollback Steps**
   ```bash
   # Mark release as known-bad
   # Create GitHub release note about issue
   
   # If removing tag:
   git tag -d v1.2.3
   git push origin :refs/tags/v1.2.3
   
   # Point users to previous version
   ```

4. **Communication**
   - Notify users of issue
   - Provide workaround if available
   - ETA for fix

---

## Version Numbering

Following [Semantic Versioning](https://semver.org/):

| Type | When |
|------|------|
| **Major (X.0.0)** | Breaking changes |
| **Minor (0.X.0)** | New features, backwards compatible |
| **Patch (0.0.X)** | Bug fixes, backwards compatible |

### Breaking Changes Include

- Renamed scripts or flags
- Changed default behavior
- Removed features
- Changed configuration format
- Changed minimum versions

---

*Last updated: 2026-01-31*
