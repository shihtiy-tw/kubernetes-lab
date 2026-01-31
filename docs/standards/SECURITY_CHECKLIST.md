# Security Checklist

Security review checklist for kubernetes-lab code and configurations.

## Quick Checks

- [ ] No hardcoded credentials
- [ ] No secrets in code or config
- [ ] Proper RBAC configuration
- [ ] Resource limits set

---

## Shell Scripts

### Credential Handling

- [ ] No hardcoded AWS keys
- [ ] No embedded passwords
- [ ] Uses environment variables for secrets
- [ ] Secrets loaded from secure sources (AWS Secrets Manager, etc.)

### Input Validation

- [ ] User inputs are validated
- [ ] Special characters are escaped/quoted
- [ ] Path traversal prevented
- [ ] Command injection prevented

```bash
# Good - quoted variable
kubectl apply -f "$USER_FILE"

# Bad - unquoted, potential injection
kubectl apply -f $USER_FILE
```

### Secure Defaults

- [ ] Least privilege principle applied
- [ ] Verbose/debug mode doesn't leak secrets
- [ ] Temporary files are cleaned up
- [ ] Sensitive data not logged

---

## Kubernetes Configurations

### Pod Security

- [ ] `runAsNonRoot: true` where possible
- [ ] `readOnlyRootFilesystem: true` where possible
- [ ] Dropped capabilities (`drop: ALL`)
- [ ] No privileged containers

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

### Network Security

- [ ] NetworkPolicies defined
- [ ] Minimal ingress/egress rules
- [ ] No unnecessary exposed ports

### RBAC

- [ ] Minimal required permissions
- [ ] No cluster-admin unless necessary
- [ ] ServiceAccount per workload
- [ ] RoleBinding scope is appropriate

```yaml
# Good - namespace-scoped
kind: Role
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]

# Avoid - cluster-wide
kind: ClusterRole
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
```

### Secrets Management

- [ ] Secrets not in ConfigMaps
- [ ] External secrets integration where possible
- [ ] Secrets have appropriate RBAC
- [ ] Rotation policy documented

---

## AWS/Cloud Security

### IAM

- [ ] IAM roles follow least privilege
- [ ] No inline policies with `*` permissions
- [ ] IRSA (IAM Roles for Service Accounts) used
- [ ] No long-term credentials in pods

### Network

- [ ] Security groups are minimal
- [ ] VPC endpoints for AWS services
- [ ] No public subnets for workers (unless required)
- [ ] NACLs as defense in depth

### EKS Specific

- [ ] Public endpoint access restricted (if enabled)
- [ ] Envelope encryption enabled
- [ ] Audit logging enabled
- [ ] Secrets encryption enabled

---

## Supply Chain Security

### Container Images

- [ ] Using specific image tags (not `latest`)
- [ ] Images from trusted registries
- [ ] Image signatures verified (if available)
- [ ] Base images are up to date

```yaml
# Good
image: nginx:1.25.3

# Bad
image: nginx:latest
image: nginx
```

### Dependencies

- [ ] Helm charts from trusted sources
- [ ] Chart versions pinned
- [ ] Dependencies audited for vulnerabilities
- [ ] Update policy documented

---

## CI/CD Security

### Pipeline Security

- [ ] Secrets stored in secure location
- [ ] No secrets in logs
- [ ] Protected branches configured
- [ ] Required reviews enabled

### Secret Scanning

- [ ] Pre-commit hooks for secrets
- [ ] CI secret scanning enabled
- [ ] Known secrets baseline maintained

---

## Logging & Monitoring

### Audit Trail

- [ ] Actions are logged
- [ ] Logs don't contain secrets
- [ ] Log retention policy defined
- [ ] Tamper-evident logging

### Alerting

- [ ] Security events trigger alerts
- [ ] Failed authentication logged
- [ ] Privilege escalation detected
- [ ] Anomaly detection in place

---

## Compliance

### Documentation

- [ ] Security decisions documented
- [ ] Exceptions documented with justification
- [ ] Runbook for security incidents
- [ ] Contact information for security issues

### Reviews

- [ ] Regular security reviews scheduled
- [ ] Dependencies audited periodically
- [ ] Access reviews conducted
- [ ] Incident response tested

---

## Pre-Deployment Checklist

Before deploying to production:

- [ ] All security checks above satisfied
- [ ] Vulnerability scan completed
- [ ] Penetration test (if applicable)
- [ ] Security team review (if required)
- [ ] Compliance requirements met

---

## Tools

| Tool | Purpose | Check |
|------|---------|-------|
| detect-secrets | Secret scanning | Pre-commit |
| tfsec | Terraform security | CI |
| kube-score | K8s security scoring | CI |
| trivy | Container scanning | CI |
| kube-bench | CIS benchmarks | Manual |
| kubeaudit | Cluster audit | Manual |

---

*Last updated: 2026-01-31*
