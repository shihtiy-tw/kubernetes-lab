# EKS Addons Test Cases

This directory contains test cases for all EKS addon installation scripts.

## Test Strategy

### Before Refactoring
1. Document current behavior (baseline)
2. Create test cases for expected behavior
3. Run tests - they will FAIL (scripts not yet compliant)

### After Refactoring
1. Run tests - they should PASS
2. Verify functionality unchanged

---

## Addon Test Cases

### aws-load-balancer-controller

**Script**: `eks/addons/aws-load-balancer-controller/build.sh`

| Test ID | Test Case | Expected Behavior |
|---------|-----------|-------------------|
| ALBC-001 | `--help` flag | Displays usage info, exits 0 |
| ALBC-002 | `--version` flag | Shows version, exits 0 |
| ALBC-003 | `--list-versions` | Lists available Helm chart versions |
| ALBC-004 | `--dry-run` | Shows what would happen without executing |
| ALBC-005 | Invalid flag | Exits with code 1, shows error |
| ALBC-006 | `--cluster` override | Uses specified cluster instead of context |
| ALBC-007 | `--skip-iam` | Skips IAM policy creation |

**Current Status**: ✅ Already refactored

---

### ingress-nginx-controller

**Script**: `eks/addons/ingress-nginx-controller/build.sh`

| Test ID | Test Case | Expected Behavior |
|---------|-----------|-------------------|
| NGINX-001 | `--help` flag | Displays usage info, exits 0 |
| NGINX-002 | `--version` flag | Shows version, exits 0 |
| NGINX-003 | `--list-versions` | Lists available Helm chart versions |
| NGINX-004 | `--dry-run` | Shows what would happen |
| NGINX-005 | Invalid flag | Exits with code 1 |

**Current Status**: ❌ Needs refactoring

---

### cert-manager (future shared plugin)

**Expected location**: `shared/plugins/cert-manager/install.sh`

| Test ID | Test Case | Expected Behavior |
|---------|-----------|-------------------|
| CERT-001 | `--help` flag | Displays usage info, exits 0 |
| CERT-002 | `--version` flag | Shows version, exits 0 |
| CERT-003 | `--namespace` | Installs to specified namespace |
| CERT-004 | `--dry-run` | Shows what would happen |

---

### cluster-autoscaler

**Script**: `eks/addons/cluster-autoscaler/build.sh`

| Test ID | Test Case | Expected Behavior |
|---------|-----------|-------------------|
| CA-001 | `--help` flag | Displays usage info, exits 0 |
| CA-002 | `--version` flag | Shows version, exits 0 |
| CA-003 | `--cluster` | Uses specified cluster |
| CA-004 | `--dry-run` | Shows what would happen |

**Current Status**: ❌ Needs refactoring

---

### karpenter

**Script**: `eks/addons/karpenter/build.sh`

| Test ID | Test Case | Expected Behavior |
|---------|-----------|-------------------|
| KARP-001 | `--help` flag | Displays usage info, exits 0 |
| KARP-002 | `--version` flag | Shows version, exits 0 |
| KARP-003 | `--cluster` | Uses specified cluster |
| KARP-004 | `--dry-run` | Shows what would happen |

**Current Status**: ❌ Needs refactoring

---

### aws-ebs-csi-driver

**Script**: `eks/addons/aws-ebs-csi-driver/build.sh`

| Test ID | Test Case | Expected Behavior |
|---------|-----------|-------------------|
| EBS-001 | `--help` flag | Displays usage info, exits 0 |
| EBS-002 | `--version` flag | Shows version, exits 0 |
| EBS-003 | `--dry-run` | Shows what would happen |

**Current Status**: ❌ Needs refactoring

---

## Running Tests

### Test Single Script
```bash
./tests/test-cli-12factor.sh eks/addons/aws-load-balancer-controller/build.sh
```

### Test All Addons
```bash
./tests/test-cli-12factor.sh --addons
```

### Test Everything
```bash
./tests/test-cli-12factor.sh --all
```

---

## Test Results Tracking

| Date | Addons Tested | Passed | Failed |
|------|---------------|--------|--------|
| 2026-01-30 | 1/11 | 1 | 10 |

---

## Notes

- Tests use `--help` and `--version` flags which should be safe to run
- Tests do NOT execute actual installation (no AWS calls)
- Invalid flag test verifies proper error handling
