# Troubleshooting Guide

Common issues and solutions for kubernetes-lab.

## Quick Diagnostics

```bash
# Check cluster connectivity
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check all pods (including system)
kubectl get pods -A

# Recent events
kubectl get events --sort-by='.lastTimestamp' -A | tail -20

# Check script permissions
ls -la eks/addons/*/install.sh
```

## Common Issues

### 1. Script Permission Denied

**Symptom:**
```
bash: ./install.sh: Permission denied
```

**Solution:**
```bash
chmod +x ./install.sh
# Or for all scripts:
find . -name "*.sh" -exec chmod +x {} \;
```

### 2. Command Not Found

**Symptom:**
```
install.sh: line 42: kubectl: command not found
```

**Solution:**
```bash
# Check if installed
which kubectl helm aws kind

# Install missing tools
./scripts/install-deps.sh
```

### 3. Cluster Not Accessible

**Symptom:**
```
Error: Kubernetes cluster unreachable
```

**Diagnosis:**
```bash
# Check kubeconfig
echo $KUBECONFIG
kubectl config current-context
kubectl cluster-info
```

**Solutions:**

For EKS:
```bash
aws eks update-kubeconfig --name <cluster> --region <region>
```

For Kind:
```bash
kind get clusters
kubectl cluster-info --context kind-<cluster-name>
```

### 4. Helm Release Already Exists

**Symptom:**
```
Error: cannot re-use a name that is still in use
```

**Solution:**
```bash
# Check existing releases
helm list -n <namespace>

# Uninstall first
helm uninstall <release-name> -n <namespace>

# Or use upgrade with --install (default in our scripts)
helm upgrade --install <release-name> ...
```

### 5. Namespace Not Found

**Symptom:**
```
Error: namespaces "my-namespace" not found
```

**Solution:**
```bash
# Our scripts create namespace automatically
# But if manual:
kubectl create namespace <namespace>
```

### 6. AWS Credentials Error

**Symptom:**
```
An error occurred (ExpiredTokenException)
```

**Solution:**
```bash
# Refresh credentials
aws sso login --profile <profile>

# Or re-configure
aws configure

# Verify identity
aws sts get-caller-identity
```

### 7. Insufficient Permissions (RBAC)

**Symptom:**
```
Error: forbidden: User "system:..." cannot create ...
```

**Diagnosis:**
```bash
kubectl auth can-i create deployments -n <namespace>
kubectl auth can-i '*' '*' --all-namespaces  # admin check
```

**Solution:**
Ensure your user/role has appropriate permissions. For EKS:
```bash
eksctl create iamidentitymapping \
  --cluster <cluster> \
  --arn <role-arn> \
  --group system:masters
```

### 8. Pod Stuck in Pending

**Symptom:**
```
NAME        READY   STATUS    RESTARTS   AGE
my-pod      0/1     Pending   0          5m
```

**Diagnosis:**
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl get events -n <namespace>
```

**Common Causes:**
- Insufficient resources → Add more nodes or reduce requests
- No matching nodes → Check node selectors/tolerations
- PVC not bound → Check storage class and PVCs

### 9. Image Pull Error

**Symptom:**
```
Failed to pull image: rpc error: code = Unknown
```

**Diagnosis:**
```bash
kubectl describe pod <pod-name> -n <namespace>
```

**Solutions:**
```bash
# Public image - check image name/tag
# Private registry - create secret
kubectl create secret docker-registry <name> \
  --docker-server=<registry> \
  --docker-username=<user> \
  --docker-password=<password>
```

### 10. Dry Run Doesn't Match Actual

**Symptom:**
```
Dry run succeeded but actual install failed
```

**Explanation:**
Dry run validates syntax but can't check:
- Runtime dependencies
- Cluster state
- External services

**Solution:**
- Check prerequisites manually
- Review error message carefully
- Test on non-production first

## Addon-Specific Issues

### ingress-nginx

**Issue:** No external IP
```bash
kubectl get svc -n ingress-nginx
# NAME                TYPE           EXTERNAL-IP
# ingress-nginx       LoadBalancer   <pending>
```

**For Kind:**
```bash
# Kind needs NodePort or port-forward
kubectl port-forward svc/ingress-nginx-controller 8080:80 -n ingress-nginx
```

**For EKS:**
```bash
# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer
```

### cert-manager

**Issue:** Certificate not ready
```bash
kubectl describe certificate -n <namespace>
kubectl describe certificaterequest -n <namespace>
kubectl logs -n cert-manager deploy/cert-manager
```

### external-dns

**Issue:** DNS records not created
```bash
kubectl logs -n external-dns deploy/external-dns
# Check IAM permissions for Route53
```

## Debug Mode

Enable verbose output:
```bash
./install.sh --cluster <name> --verbose
```

Enable Helm debug:
```bash
HELM_DEBUG=1 ./install.sh --cluster <name>
```

## Collecting Information for Bug Reports

```bash
# System info
uname -a
bash --version

# Tool versions
./scripts/check-versions.sh 2>&1

# Cluster info
kubectl version
kubectl get nodes -o wide

# Script output (with verbose)
./install.sh --cluster <name> --verbose 2>&1 | tee install.log
```

## Getting Help

1. Check the [FAQ](FAQ.md)
2. Search [existing issues](https://github.com/org/kubernetes-lab/issues)
3. Ask in discussions
4. Open a new issue with debug info

---

*Last updated: 2026-01-31*
