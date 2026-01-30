# EKS Scenarios Test Cases

This directory contains test cases for all EKS scenario scripts.

## Scenarios Inventory

| Scenario | Script | Status |
|----------|--------|--------|
| load-balancers/alb-graceful-shutdown | build.sh | ❌ Needs refactoring |
| load-balancers/alb-hostname-routing | build.sh | ❌ Needs refactoring |
| load-balancers/alb-https | build.sh | ❌ Needs refactoring |
| load-balancers/alb-listener-port | build.sh | ❌ Needs refactoring |
| load-balancers/alb-listener-rule | build.sh | ❌ Needs refactoring |
| load-balancers/alb-mtls | build.sh | ❌ Needs refactoring |
| load-balancers/cross-vpc-nlb | build.sh | ❌ Needs refactoring |
| karpenter/general | build.sh | ❌ Needs refactoring |
| pod-identity/s3 | build.sh | ❌ Needs refactoring |
| access-entry | set.sh | ❌ Needs refactoring |
| appmesh | build.sh | ❌ Needs refactoring |
| cloudwatch-observability | build.sh | ❌ Needs refactoring |
| irsa | build.sh | ❌ Needs refactoring |
| high-services-number | create_services_parallel.sh | ❌ Needs refactoring |
| high-services-number | delete_services_parallel.sh | ❌ Needs refactoring |

---

## Test Cases

### load-balancers/alb-graceful-shutdown

**Script**: `eks/scenarios/load-balancers/alb-graceful-shutdown/build.sh`

| Test ID | Test Case | Expected Behavior |
|---------|-----------|-------------------|
| ALB-GS-001 | `--help` flag | Displays usage info, exits 0 |
| ALB-GS-002 | `--version` flag | Shows version, exits 0 |
| ALB-GS-003 | `--namespace` | Deploys to specified namespace |
| ALB-GS-004 | `--dry-run` | Shows manifests without applying |
| ALB-GS-005 | Invalid flag | Exits with code 1 |

---

### load-balancers/alb-https

**Script**: `eks/scenarios/load-balancers/alb-https/build.sh`

| Test ID | Test Case | Expected Behavior |
|---------|-----------|-------------------|
| ALB-HTTPS-001 | `--help` flag | Displays usage info, exits 0 |
| ALB-HTTPS-002 | `--version` flag | Shows version, exits 0 |
| ALB-HTTPS-003 | `--domain` | Uses specified domain |
| ALB-HTTPS-004 | `--certificate-arn` | Uses specified ACM cert |
| ALB-HTTPS-005 | `--dry-run` | Shows manifests without applying |

---

### pod-identity/s3

**Script**: `eks/scenarios/pod-identity/s3/build.sh`

| Test ID | Test Case | Expected Behavior |
|---------|-----------|-------------------|
| PI-S3-001 | `--help` flag | Displays usage info, exits 0 |
| PI-S3-002 | `--version` flag | Shows version, exits 0 |
| PI-S3-003 | `--bucket` | Uses specified S3 bucket |
| PI-S3-004 | `--cluster` | Uses specified cluster |
| PI-S3-005 | `--dry-run` | Shows what would happen |

---

### karpenter/general

**Script**: `eks/scenarios/karpenter/general/build.sh`

| Test ID | Test Case | Expected Behavior |
|---------|-----------|-------------------|
| KARP-GEN-001 | `--help` flag | Displays usage info, exits 0 |
| KARP-GEN-002 | `--version` flag | Shows version, exits 0 |
| KARP-GEN-003 | `--namespace` | Deploys to specified namespace |
| KARP-GEN-004 | `--dry-run` | Shows manifests without applying |

---

## Running Tests

### Test Single Scenario
```bash
./tests/test-cli-12factor.sh eks/scenarios/load-balancers/alb-https/build.sh
```

### Test All Scenarios
```bash
./tests/test-cli-12factor.sh --scenarios
```

---

## Functional Tests (KUTTL)

For scenarios that deploy Kubernetes resources, we also have KUTTL tests:

```bash
# Run KUTTL tests for load-balancer scenarios
kubectl kuttl test --config eks/tests/scenarios/kuttl-load-balancers.yaml
```

### KUTTL Test Structure

```
eks/tests/scenarios/
├── kuttl-load-balancers.yaml     # Test suite config
├── alb-https/
│   ├── 00-assert.yaml            # Pre-conditions
│   ├── 01-deploy.yaml            # Deploy resources
│   └── 02-verify.yaml            # Verify behavior
└── alb-graceful-shutdown/
    ├── 00-assert.yaml
    ├── 01-deploy.yaml
    └── 02-verify.yaml
```

---

## Test Results Tracking

| Date | Scenarios Tested | Passed | Failed |
|------|------------------|--------|--------|
| 2026-01-30 | 0/15 | 0 | 15 |

---

## Notes

- CLI tests verify script interface compliance
- KUTTL tests verify Kubernetes resource behavior
- Both should pass before considering a scenario "complete"
