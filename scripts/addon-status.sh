#!/usr/bin/env bash
#
# addon-status.sh - Check status of all installed addons
# Part of kubernetes-lab (Spec 003: Addon Standards)
#
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Symbols
CHECK="✅"
CROSS="❌"
WARN="⚠️"

# Default values
PLATFORM=""
OUTPUT_FORMAT="table"
VERBOSE=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Check the status of all Kubernetes addons on the current cluster.

Options:
    --platform PLATFORM     Filter by platform: shared, eks, gke, aks, kind
    --format FORMAT         Output format: table, json, yaml (default: table)
    --verbose               Show detailed status
    --help                  Show this help message
    --version               Show script version

Examples:
    # Check all addons
    $SCRIPT_NAME

    # Check only EKS addons
    $SCRIPT_NAME --platform eks

    # JSON output
    $SCRIPT_NAME --format json
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --platform)
                PLATFORM="$2"
                shift 2
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            --version)
                echo "$SCRIPT_NAME version $VERSION"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl not found${NC}"
        exit 1
    fi

    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
}

# Check if a Helm release exists
check_helm_release() {
    local name="$1"
    local namespace="$2"
    
    if helm status "$name" -n "$namespace" &> /dev/null; then
        local version
        version=$(helm list -n "$namespace" -f "^${name}$" -o json | jq -r '.[0].chart' | sed 's/.*-//')
        echo "$version"
        return 0
    fi
    return 1
}

# Check if pods are running
check_pods_running() {
    local namespace="$1"
    local label="$2"
    
    local ready
    ready=$(kubectl get pods -n "$namespace" -l "$label" -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>/dev/null | tr ' ' '\n' | grep -c true || echo 0)
    local total
    total=$(kubectl get pods -n "$namespace" -l "$label" --no-headers 2>/dev/null | wc -l || echo 0)
    
    if [[ $total -gt 0 && $ready -eq $total ]]; then
        echo "$ready/$total"
        return 0
    elif [[ $total -gt 0 ]]; then
        echo "$ready/$total"
        return 1
    fi
    return 2
}

# Define addon checks
declare -A ADDON_CHECKS=(
    # Shared addons
    ["cert-manager"]="helm:cert-manager:cert-manager|app.kubernetes.io/name=cert-manager"
    ["metrics-server"]="helm:metrics-server:kube-system|app.kubernetes.io/name=metrics-server"
    ["ingress-nginx"]="helm:ingress-nginx:ingress-nginx|app.kubernetes.io/name=ingress-nginx"
    ["external-dns"]="helm:external-dns:external-dns|app.kubernetes.io/name=external-dns"
    ["prometheus-stack"]="helm:prometheus-stack:monitoring|app.kubernetes.io/name=kube-prometheus-stack"
    ["argocd"]="helm:argocd:argocd|app.kubernetes.io/name=argocd-server"
    ["external-secrets"]="helm:external-secrets:external-secrets|app.kubernetes.io/name=external-secrets"
    ["keda"]="helm:keda:keda|app.kubernetes.io/name=keda-operator"
    
    # EKS addons
    ["aws-load-balancer-controller"]="helm:aws-load-balancer-controller:kube-system|app.kubernetes.io/name=aws-load-balancer-controller"
    ["cluster-autoscaler"]="helm:cluster-autoscaler:kube-system|app.kubernetes.io/name=cluster-autoscaler"
    ["karpenter"]="helm:karpenter:karpenter|app.kubernetes.io/name=karpenter"
    
    # GKE addons
    ["config-connector"]="kubectl:configconnector-operator-system|cnrm.cloud.google.com/component=cnrm-controller-manager"
    
    # AKS addons
    ["aad-pod-identity"]="helm:aad-pod-identity:kube-system|app.kubernetes.io/name=aad-pod-identity"
    
    # Kind addons
    ["metallb"]="helm:metallb:metallb-system|app.kubernetes.io/name=metallb"
    ["local-path-provisioner"]="kubectl:local-path-storage|app=local-path-provisioner"
)

# Platform mapping
declare -A ADDON_PLATFORMS=(
    ["cert-manager"]="shared"
    ["metrics-server"]="shared"
    ["ingress-nginx"]="shared"
    ["external-dns"]="shared"
    ["prometheus-stack"]="shared"
    ["argocd"]="shared"
    ["external-secrets"]="shared"
    ["keda"]="shared"
    ["aws-load-balancer-controller"]="eks"
    ["cluster-autoscaler"]="eks"
    ["karpenter"]="eks"
    ["config-connector"]="gke"
    ["aad-pod-identity"]="aks"
    ["metallb"]="kind"
    ["local-path-provisioner"]="kind"
)

check_addon() {
    local addon="$1"
    local check_spec="${ADDON_CHECKS[$addon]:-}"
    
    if [[ -z "$check_spec" ]]; then
        echo "UNKNOWN"
        return
    fi
    
    local method namespace label
    method=$(echo "$check_spec" | cut -d: -f1)
    namespace=$(echo "$check_spec" | cut -d: -f2 | cut -d'|' -f1)
    label=$(echo "$check_spec" | cut -d'|' -f2)
    
    local version=""
    local status="NOT INSTALLED"
    local pods=""
    
    if [[ "$method" == "helm" ]]; then
        local release
        release=$(echo "$check_spec" | cut -d: -f2)
        namespace=$(echo "$check_spec" | cut -d: -f3 | cut -d'|' -f1)
        
        if version=$(check_helm_release "$release" "$namespace" 2>/dev/null); then
            pods=$(check_pods_running "$namespace" "$label" 2>/dev/null || echo "0/0")
            if [[ "$pods" != "0/0" ]] && [[ "${pods%/*}" == "${pods#*/}" ]]; then
                status="OK"
            else
                status="DEGRADED"
            fi
        fi
    elif [[ "$method" == "kubectl" ]]; then
        if kubectl get namespace "$namespace" &> /dev/null; then
            pods=$(check_pods_running "$namespace" "$label" 2>/dev/null || echo "0/0")
            if [[ "$pods" != "0/0" ]]; then
                status="OK"
                version="installed"
            fi
        fi
    fi
    
    echo "$status|$version|$namespace|$pods"
}

print_table_header() {
    printf "%-35s %-12s %-12s %-15s" "ADDON" "STATUS" "VERSION" "NAMESPACE"
    if [[ "$VERBOSE" == "true" ]]; then
        printf " %-10s" "PODS"
    fi
    echo ""
    printf "%s\n" "$(printf '=%.0s' {1..80})"
}

print_table_row() {
    local addon="$1"
    local status="$2"
    local version="$3"
    local namespace="$4"
    local pods="$5"
    
    local status_icon
    case "$status" in
        OK) status_icon="${GREEN}${CHECK} OK${NC}" ;;
        DEGRADED) status_icon="${YELLOW}${WARN} DEGRADED${NC}" ;;
        *) status_icon="${RED}${CROSS} NOT${NC}" ;;
    esac
    
    printf "%-35s " "$addon"
    printf "%-20b " "$status_icon"
    printf "%-12s %-15s" "${version:--}" "${namespace:--}"
    if [[ "$VERBOSE" == "true" ]]; then
        printf " %-10s" "${pods:--}"
    fi
    echo ""
}

main() {
    parse_args "$@"
    check_kubectl
    
    echo -e "${CYAN}Kubernetes Addon Status${NC}"
    echo -e "Cluster: $(kubectl config current-context)"
    echo ""
    
    print_table_header
    
    for addon in "${!ADDON_CHECKS[@]}"; do
        local addon_platform="${ADDON_PLATFORMS[$addon]:-unknown}"
        
        # Filter by platform if specified
        if [[ -n "$PLATFORM" && "$addon_platform" != "$PLATFORM" ]]; then
            continue
        fi
        
        local result
        result=$(check_addon "$addon")
        
        local status version namespace pods
        IFS='|' read -r status version namespace pods <<< "$result"
        
        print_table_row "$addon" "$status" "$version" "$namespace" "$pods"
    done
}

main "$@"
