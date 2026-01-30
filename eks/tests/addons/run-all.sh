#!/usr/bin/env bash
# Run all addon tests
# Reports baseline compliance before refactoring

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}EKS Addons CLI 12-Factor Compliance Report${NC}"
echo -e "${BLUE}Date: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}================================================${NC}"

ADDONS_PASSED=0
ADDONS_FAILED=0
ADDONS_TOTAL=0

# List of addons to test
ADDONS=(
    "aws-load-balancer-controller"
    "ingress-nginx-controller"
    "cluster-autoscaler"
    "karpenter"
    "aws-ebs-csi-driver"
    "cert-manager"  # May not exist yet
    "appmesh-controller"
    "amazon-cloudwatch-observability"
    "eks-pod-identity-agent"
    "kubecost"
    "nvidia-gpu-operator"
    "nvidia-k8s-device-plugin"
    "secrets-store-csi-driver"
    "trident-csi"
)

# Test a single addon using the main test framework
test_addon() {
    local addon_name="$1"
    local addon_script="$SCRIPT_DIR/../../addons/${addon_name}/build.sh"
    
    ((ADDONS_TOTAL++))
    
    if [[ ! -f "$addon_script" ]]; then
        echo -e "\n${YELLOW}SKIP:${NC} $addon_name (script not found)"
        return 0
    fi
    
    echo -e "\n${YELLOW}Testing:${NC} $addon_name"
    
    local result=0
    
    # Quick compliance checks
    local checks=0
    local passed=0
    
    # Check 1: Has --help
    ((checks++))
    if grep -q '\-\-help' "$addon_script" 2>/dev/null; then
        ((passed++))
    fi
    
    # Check 2: Has --version
    ((checks++))
    if grep -q '\-\-version' "$addon_script" 2>/dev/null; then
        ((passed++))
    fi
    
    # Check 3: Has strict mode
    ((checks++))
    if grep -q 'set -e' "$addon_script" 2>/dev/null; then
        ((passed++))
    fi
    
    # Check 4: Has #!/usr/bin/env bash
    ((checks++))
    if head -n1 "$addon_script" | grep -q '#!/usr/bin/env bash' 2>/dev/null; then
        ((passed++))
    fi
    
    # Check 5: --help actually works
    ((checks++))
    if "$addon_script" --help > /dev/null 2>&1; then
        ((passed++))
    fi
    
    # Report
    if [[ $passed -eq $checks ]]; then
        echo -e "  ${GREEN}✓${NC} $passed/$checks checks passed - COMPLIANT"
        ((ADDONS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $passed/$checks checks passed - NEEDS REFACTORING"
        ((ADDONS_FAILED++))
    fi
}

# Run all tests
for addon in "${ADDONS[@]}"; do
    test_addon "$addon"
done

# Summary
echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "Total Addons Tested:  $ADDONS_TOTAL"
echo -e "Compliant:            ${GREEN}$ADDONS_PASSED${NC}"
echo -e "Need Refactoring:     ${RED}$ADDONS_FAILED${NC}"
echo ""

if [[ $ADDONS_FAILED -gt 0 ]]; then
    echo -e "${YELLOW}Run individual tests to see specific failures:${NC}"
    echo "  ./eks/tests/addons/test-ingress-nginx.sh"
    echo "  ./eks/tests/addons/test-cluster-autoscaler.sh"
    echo "  ./eks/tests/addons/test-karpenter.sh"
fi
