#!/usr/bin/env bash
# ALB HTTPS Scenario with ACM and Route53
# CLI 12-Factor Compliant

set -euo pipefail

SCRIPT_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Deploy ALB with HTTPS using ACM certificate and Route53.

OPTIONS:
    --apply               Apply the configuration (default)
    --delete              Delete the configuration
    --dry-run             Show what would be deployed
    --skip-terraform      Skip Terraform apply (use existing resources)
    -h, --help            Show this help message
    -v, --version         Show script version

PREREQUISITES:
    - AWS Load Balancer Controller installed
    - external-dns installed (optional, for DNS records)
    - Terraform initialized in ./terraform/

EXAMPLES:
    # Deploy
    $(basename "$0")

    # Dry run
    $(basename "$0") --dry-run

    # Delete
    $(basename "$0") --delete

    # Deploy without running Terraform
    $(basename "$0") --skip-terraform
EOF
}

show_version() {
    echo "$(basename "$0") version ${SCRIPT_VERSION}"
}

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&1; }
log_success() { echo -e "${GREEN}[OK]${NC} $*" >&1; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "\n${YELLOW}=== $* ===${NC}" >&1; }

# Defaults
ACTION="apply"
DRY_RUN=false
SKIP_TERRAFORM=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --apply)
            ACTION="apply"
            shift
            ;;
        --delete)
            ACTION="delete"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-terraform)
            SKIP_TERRAFORM=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Run '$(basename "$0") --help' for usage." >&2
            exit 1
            ;;
    esac
done

# Delete resources
delete_resources() {
    log_step "Deleting Resources"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would delete Kubernetes resources"
        log_info "[DRY RUN] Would run terraform destroy"
        exit 0
    fi
    
    cd "$SCRIPT_DIR"
    kustomize build . | kubectl delete -f - 2>/dev/null || true
    
    if [[ -d "${SCRIPT_DIR}/terraform" ]]; then
        terraform -chdir="${SCRIPT_DIR}/terraform" destroy -auto-approve 2>/dev/null || true
    fi
    
    log_success "Resources deleted"
    exit 0
}

# Main
main() {
    cd "$SCRIPT_DIR"
    
    if [[ "$ACTION" == "delete" ]]; then
        delete_resources
    fi

    log_step "Configuration"
    
    # Get service name from k8s manifest
    local service_name=""
    if [[ -f "k8s-service.yaml" ]]; then
        service_name=$(yq -r ".metadata.name" k8s-service.yaml 2>/dev/null || echo "")
        log_info "Service Name: $service_name"
    fi
    
    # Get name prefix from kustomization
    local name_prefix=""
    if [[ -f "kustomization.yaml" ]]; then
        name_prefix=$(yq -r ".namePrefix // \"\"" kustomization.yaml 2>/dev/null || echo "")
        log_info "Name Prefix: $name_prefix"
    fi

    # Terraform setup
    local acm_cert_arn=""
    local zone_id=""
    local hosted_zone_name=""
    local host_name=""
    
    if ! $SKIP_TERRAFORM && [[ -d "terraform" ]]; then
        log_step "Terraform"
        
        if $DRY_RUN; then
            log_info "[DRY RUN] Would run: terraform -chdir=./terraform apply"
        else
            terraform -chdir=./terraform apply -auto-approve
        fi
        
        acm_cert_arn=$(terraform -chdir=terraform output -raw acm_certificate_arn 2>/dev/null || echo "")
        zone_id=$(terraform -chdir=terraform output -raw route53_zone_id 2>/dev/null || echo "")
    fi
    
    # Get Route53 info
    if [[ -n "$zone_id" ]]; then
        hosted_zone_name=$(aws route53 get-hosted-zone --id "$zone_id" --query 'HostedZone.Name' --output text 2>/dev/null || echo "example.com")
        host_name="alb.${hosted_zone_name}"
        log_info "ACM Certificate: $acm_cert_arn"
        log_info "Hosted Zone: $hosted_zone_name"
        log_info "Host Name: $host_name"
    fi

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would apply Kustomize configuration"
        log_info "Would substitute:"
        log_info "  - Service name: ${name_prefix}${service_name}"
        log_info "  - Certificate ARN: $acm_cert_arn"
        log_info "  - Host name: $host_name"
        exit 0
    fi

    # Apply Kubernetes resources
    log_step "Deploying Kubernetes Resources"
    
    if [[ -n "$acm_cert_arn" ]] && [[ -n "$hosted_zone_name" ]]; then
        kustomize build . \
            | sed -e "/annotations:/,/spec:/s/${service_name}/${name_prefix}${service_name}/g" \
            | sed -e "/annotations:/,/spec:/s~example-certificate-arn~${acm_cert_arn}~g" \
            | sed -e "/annotations:/,/spec:/s/example.com/${host_name%.*}/g" \
            | sed -e "/args:/,/image:/s/example.com/${hosted_zone_name%.*}/g" \
            | kubectl apply -f -
    else
        kustomize build . | kubectl apply -f -
    fi
    
    log_success "Resources deployed"

    log_step "Complete"
    log_info "ALB HTTPS configuration applied"
    [[ -n "$host_name" ]] && log_info "URL: https://${host_name}"
    log_info "Check ingress: kubectl get ingress"
    exit 0
}

main "$@"
