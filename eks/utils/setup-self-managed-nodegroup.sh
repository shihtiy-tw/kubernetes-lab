#!/bin/bash
# =============================================================================
# setup-self-managed-nodegroup.sh - Create EKS Self-Managed NodeGroups
# =============================================================================
#
# Usage:
#   ./utils/setup-self-managed-nodegroup.sh [OPTIONS]
#
# Options:
#   --version, -v       Kubernetes version (e.g., 1.33)
#   --region, -r        AWS region (e.g., us-east-1)
#   --cluster, -c       Cluster name
#   --config            Cluster config type (minimal|full|auto)
#   --nodegroup-type, -t Nodegroup config type (on-demand|spot|multi-ami|etc)
#   --instance-type, -i Instance type (e.g., t3.medium)
#   --dry-run           Simulate execution
#   -h, --help          Show usage
#
# =============================================================================

# Calculate script directory for robust path handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source helper scripts
source "$SCRIPT_DIR/detect-context.sh"

# Default values
DRY_RUN=false
EKS_VERSION=""
AWS_REGION=""
CLUSTER_CONFIG=""
NODEGROUP_TYPE=""
INSTANCE_TYPE_ARG=""

# Show usage helper
usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --version, -v <ver>        Kubernetes version (e.g. 1.33)"
    echo "  --region, -r <region>      AWS region"
    echo "  --cluster, -c <name>       Cluster name"
    echo "  --config <type>            Cluster config (minimal|full)"
    echo "  --nodegroup-type, -t <type> Nodegroup type (on-demand, spot, multi-ami)"
    echo "  --instance-type, -i <type>  Instance type (e.g. m5.large)"
    echo "  --dry-run                  Dry run mode"
    exit 1
}

# --- Argument Parsing ---
# Check for legacy positional arguments (heuristic: $1 is a version number)
if [[ "$1" =~ ^[0-9]+\.[0-9]+$ ]]; then
    log_warn "Deprecated: Positional arguments are deprecated. Please use flags (e.g., --version, --region)."
    EKS_VERSION="$1"
    AWS_REGION="$2"
    CLUSTER_CONFIG="$3"
    NODEGROUP_TYPE="$4"
    # Handle optional 5th arg
    if [[ "$5" == "--dry-run" ]] || [[ "$5" == "--validate" ]]; then
        DRY_RUN=true
    else
        INSTANCE_TYPE_ARG="$5"
    fi

    # Check for dry-run flag in any remaining position
    for arg in "${@:6}"; do
        if [[ "$arg" == "--dry-run" ]] || [[ "$arg" == "--validate" ]]; then
            DRY_RUN=true
        fi
    done
else
    # Flag parsing
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                EKS_VERSION="$2"
                shift 2
                ;;
            -r|--region)
                AWS_REGION="$2"
                shift 2
                ;;
            -c|--cluster)
                export EKS_CLUSTER_NAME="$2"
                shift 2
                ;;
            --config)
                CLUSTER_CONFIG="$2"
                shift 2
                ;;
            -t|--nodegroup-type)
                NODEGROUP_TYPE="$2"
                shift 2
                ;;
            -i|--instance-type)
                INSTANCE_TYPE_ARG="$2"
                shift 2
                ;;
            --dry-run|--validate)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                # If it's the first argument and unrelated, it might be a shorthand nodegroup type
                if [[ -z "$NODEGROUP_TYPE" ]]; then
                     NODEGROUP_TYPE="$1"
                     shift
                else
                     log_error "Unknown argument: $1"
                     usage
                fi
                ;;
        esac
    done
fi

# --- Auto-Detection ---
# If essential details are missing, try to detect from context
if [[ -z "$EKS_VERSION" ]] && [[ -z "$EKS_CLUSTER_NAME" ]]; then
    detect_context
    EKS_VERSION="${CLUSTER_VERSION}"
    AWS_REGION="${EKS_CLUSTER_REGION}"
fi

# Set defaults if still missing
AWS_REGION="${AWS_REGION:-${EKS_CLUSTER_REGION:-us-east-1}}"
EKS_VERSION="${EKS_VERSION:-${CLUSTER_VERSION:-1.30}}"
CLUSTER_CONFIG="${CLUSTER_CONFIG:-minimal}"
NODEGROUP_TYPE="${NODEGROUP_TYPE:-on-demand}"
INSTANCE_TYPE_ARG="${INSTANCE_TYPE_ARG:-m5.large}"

# Export for config.sh
export CLUSTER_VERSION="$EKS_VERSION"
export EKS_CLUSTER_REGION="$AWS_REGION"
export CLUSTER_CONFIG="$CLUSTER_CONFIG"

# Source configuration
source "$SCRIPT_DIR/config.sh" "" "" ""
source "$SCRIPT_DIR/validate-instance.sh"

log_info "Configuration: Cluster=$EKS_CLUSTER_NAME ($CLUSTER_VERSION), Region=$EKS_CLUSTER_REGION, Type=$NODEGROUP_TYPE"

# --- Auto-detect AWS Account ID ---
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Fetch cluster details for AL2023 or Bottlerocket NodeConfig (needed for user data)
if [[ -n "$EKS_CLUSTER_NAME" ]]; then
    # We always attempt to fetch these for self-managed nodegroups if al2023 or bottlerocket is used
    # or honestly for any case where user data might need it.
    if [[ "${NODEGROUP_TYPE}" == *"al2023"* ]] || [[ "${NODEGROUP_TYPE}" == *"bottlerocket"* ]]; then
        log_info "Fetching cluster details for node configuration..."
        CLUSTER_INFO=$(aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region "$EKS_CLUSTER_REGION" --query "cluster.{Endpoint:endpoint, CA:certificateAuthority.data, CIDR:kubernetesNetworkConfig.serviceIpv4Cidr}" --output json 2>/dev/null)

        if [[ $? -eq 0 ]]; then
            export API_SERVER_ENDPOINT=$(echo "$CLUSTER_INFO" | jq -r '.Endpoint')
            export CERTIFICATE_AUTHORITY=$(echo "$CLUSTER_INFO" | jq -r '.CA')
            export SERVICE_CIDR=$(echo "$CLUSTER_INFO" | jq -r '.CIDR')
        elif [[ "$DRY_RUN" == "true" ]]; then
            log_warn "[DRY-RUN] Cluster not found. Using placeholders."
            export API_SERVER_ENDPOINT="https://PLACEHOLDER.yl4.us-east-1.eks.amazonaws.com"
            export CERTIFICATE_AUTHORITY="PLACEHOLDER_CA_DATA"
            export SERVICE_CIDR="10.100.0.0/16"
        else
            log_error "Cluster $EKS_CLUSTER_NAME not found. Cannot fetch details."
            exit 1
        fi
    fi
fi

export NODEGROUP_CONFIG="$NODEGROUP_TYPE"
export NODEGROUP_SIZE="$INSTANCE_TYPE_ARG"
export INSTANCE_TYPE="${NODEGROUP_SIZE//./}"

# Validate Instance Type
if ! validate_instance_type "$NODEGROUP_SIZE"; then
  exit 1
fi

# Create versions directory if it doesn't exist
VERSION_DIR="$PROJECT_DIR/versions/$(echo "$CLUSTER_FILE_LOCATION")"
mkdir -p "$VERSION_DIR"

export NODEGROUP_FILE="$VERSION_DIR/${EKS_CLUSTER_NAME}-${EKS_CLUSTER_REGION}-self-managed-nodegroup-${NODEGROUP_CONFIG}-${INSTANCE_TYPE}.yaml"

if [[ $NODEGROUP_CONFIG = "custom-ami" ]]; then
  # custom ami name: "eks-lab-amazon-eks-arm64-1.29-20241023145809"
  export CUSTOM_AMI=$(aws ec2 describe-images \
    --filters "Name=name,Values=eks-lab*-${CLUSTER_VERSION}-*" "Name=state,Values=available" \
    --query 'Images[*].ImageId' --output text)

  cat "$PROJECT_DIR/nodegroups/eksctl-self-managed-nodegroup-$NODEGROUP_CONFIG".yaml | envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${EKS_CLUSTER_REGION},${AZ_ARRAY},${NODEGROUP_CONFIG},${NODEGROUP_SIZE},${CUSTOM_AMI},${INSTANCE_TYPE}' > "$NODEGROUP_FILE"

elif [[ $NODEGROUP_CONFIG = "bottlerocket-userdata" ]]; then

  # https://github.com/bottlerocket-os/bottlerocket/blob/develop/QUICKSTART-EKS.md#cluster-info
  eksctl get cluster --region "$EKS_CLUSTER_REGION" --name "$EKS_CLUSTER_NAME" -o json \
   | jq --raw-output '.[] | "[settings.kubernetes]\napi-server = \"" + .Endpoint + "\"\ncluster-certificate =\"" + .CertificateAuthority.Data + "\"\ncluster-name = \"bottlerocket\""' > user-data.toml

  cat "$PROJECT_DIR/nodegroups/eksctl-managed-nodegroup-$NODEGROUP_CONFIG".yaml | envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${EKS_CLUSTER_REGION},${AZ_ARRAY},${NODEGROUP_CONFIG},${NODEGROUP_SIZE},${INSTANCE_TYPE}' > "$NODEGROUP_FILE"

elif [[ $NODEGROUP_CONFIG = "al2023-custom-ami" ]]; then
  # custom ami name: "eks-lab-amazon-eks-arm64-1.29-20241023145809"
  export CUSTOM_AMI=$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/"$CLUSTER_VERSION"/amazon-linux-2023/x86_64/standard/recommended/image_id \
    --region "$EKS_CLUSTER_REGION" --query "Parameter.Value" --output text)

  cat "$PROJECT_DIR/nodegroups/eksctl-self-managed-nodegroup-$NODEGROUP_CONFIG".yaml | envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${EKS_CLUSTER_REGION},${AZ_ARRAY},${NODEGROUP_CONFIG},${NODEGROUP_SIZE},${CUSTOM_AMI},${INSTANCE_TYPE},${API_SERVER_ENDPOINT},${CERTIFICATE_AUTHORITY},${SERVICE_CIDR}' > "$NODEGROUP_FILE"

else
  cat "$PROJECT_DIR/nodegroups/eksctl-self-managed-nodegroup-$NODEGROUP_CONFIG".yaml | envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${EKS_CLUSTER_REGION},${AZ_ARRAY},${NODEGROUP_CONFIG},${NODEGROUP_SIZE},${INSTANCE_TYPE}' > "$NODEGROUP_FILE"
fi

# envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${EKS_CLUSTER_REGION},${AZ_ARRAY},${NODEGROUP_CONFIG},${NODEGROUP_SIZE}' < $(pwd)/nodegroups/managed-nodegroup-${NODEGROUP_CONFIG}.yaml
#
log_info "EKS Nodegroup Configuration Summary:"
log_info "--------------------------------"
log_info "Cluster Name:        $EKS_CLUSTER_NAME"
log_info "Cluster Version:     $CLUSTER_VERSION"
log_info "Region:              $EKS_CLUSTER_REGION"
log_info "Availability Zones:  $AZ_ARRAY"
log_info "Cluster Config:      $CLUSTER_CONFIG"
log_info "Nodegroup Config:    $NODEGROUP_CONFIG"
log_info "Nodegroup Size:      $NODEGROUP_SIZE"
log_info "Nodegroup YAML File: $NODEGROUP_FILE"
log_info "--------------------------------"

# Capture both stdout and stderr, and store the exit status
log_info "Validating the template..."
output=$(eksctl create nodegroup -f "$NODEGROUP_FILE" --dry-run 2>&1)
exit_status=$?

# Check the exit status
if [ "$exit_status" -ne 0 ]; then
  log_error "Template validation failed"
  # Print the captured output
  echo "$output"
else
  if [[ "$DRY_RUN" == "true" ]]; then
    log_success "[DRY-RUN] Validation succeeded. Skipping execution."
    log_info "Command would be: eksctl create nodegroup -f \"$NODEGROUP_FILE\""
  else
    log_success "Template validation succeeded"
    log_info "Executing eksctl command:"
    eksctl create nodegroup -f "$NODEGROUP_FILE"
  fi
fi
