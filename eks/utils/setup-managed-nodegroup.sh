#!/bin/bash
# =============================================================================
# setup-managed-nodegroup.sh - Create EKS Managed NodeGroups
# =============================================================================
#
# Usage:
#   ./utils/setup-managed-nodegroup.sh [OPTIONS]
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
    # detect_context sets CLUSTER_VERSION, EKS_CLUSTER_REGION, EKS_CLUSTER_NAME
    EKS_VERSION="${CLUSTER_VERSION}"
    AWS_REGION="${EKS_CLUSTER_REGION}"
    # Use detected status/config if we can map it, otherwise default
fi

# Set defaults if still missing
AWS_REGION="${AWS_REGION:-${EKS_CLUSTER_REGION:-us-east-1}}"
EKS_VERSION="${EKS_VERSION:-${CLUSTER_VERSION:-1.30}}"
CLUSTER_CONFIG="${CLUSTER_CONFIG:-minimal}"
NODEGROUP_TYPE="${NODEGROUP_TYPE:-on-demand}"
INSTANCE_TYPE_ARG="${INSTANCE_TYPE_ARG:-m5.large}"

# Export for config.sh and subsequent usage
export CLUSTER_VERSION="$EKS_VERSION"
export EKS_CLUSTER_REGION="$AWS_REGION"
export CLUSTER_CONFIG="$CLUSTER_CONFIG"

# Check if we have a cluster name, passing it to config.sh via env var is safest
# config.sh will handle the final name construction/export
# Source configuration
source "$SCRIPT_DIR/config.sh" "" "" ""
source "$SCRIPT_DIR/validate-instance.sh"

log_info "Configuration: Cluster=$EKS_CLUSTER_NAME ($CLUSTER_VERSION), Region=$EKS_CLUSTER_REGION, Type=$NODEGROUP_TYPE"

# --- Auto-detect AWS Account ID ---
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Fetch cluster details for AL2023 NodeConfig (and others needing it)
if [[ -n "$EKS_CLUSTER_NAME" ]]; then
      # We might have ALREADY fetched this in detect_context, but let's be safe and consistent
    if [[ "${NODEGROUP_TYPE}" == *"al2023"* ]] || [[ "${NODEGROUP_TYPE}" == "bottlerocket-userdata" ]] || [[ "${NODEGROUP_TYPE}" == "multi-ami" ]]; then
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

# Validate the main/default instance type (unless multi-ami overrides it later)
if [[ $NODEGROUP_CONFIG != "multi-ami" ]]; then
  if ! validate_instance_type "$NODEGROUP_SIZE"; then
    exit 1
  fi
fi
export INSTANCE_TYPE="${NODEGROUP_SIZE//./}"

# TODO: change the eksctil file as eksctl-*.yaml for schema
# Create versions directory if it doesn't exist
VERSION_DIR="$PROJECT_DIR/versions/$(echo "$CLUSTER_FILE_LOCATION")"
mkdir -p "$VERSION_DIR"

export NODEGROUP_FILE="$VERSION_DIR/${EKS_CLUSTER_NAME}-${EKS_CLUSTER_REGION}-managed-nodegroup-${NODEGROUP_CONFIG}-${INSTANCE_TYPE}.yaml"

# ANSI color codes
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------
# get_minimal_instance_type <ami-id> <region>
#
# Detect the minimal EC2 instance type compatible with a given AMI.
# Steps:
#   1. Query AMI architecture (x86_64, arm64) via describe-images
#   2. Query smallest instance type for that arch via describe-instance-types
#      sorted by vCPUs then memory
#   3. Return the instance type (e.g., t3.micro for x86_64, t4g.micro for arm64)
# -----------------------------------------------------------------------
get_minimal_instance_type() {
  local ami_id="$1"
  local region="${2:-$EKS_CLUSTER_REGION}"

  # Step 1: Get AMI architecture
  local arch
  arch=$(aws ec2 describe-images \
    --image-ids "$ami_id" \
    --region "$region" \
    --query 'Images[0].Architecture' \
    --output text)


  if [[ -z "$arch" || "$arch" == "None" ]]; then
    log_warn "Error: Could not determine architecture for AMI $ami_id"
    echo "t3.medium"  # safe fallback
    return 1
  fi

  log_warn "AMI $ami_id architecture: $arch"

  # Step 2: Find smallest compatible instance type
  # Filter by architecture, current-generation, and sort by vCPU then memory
  local instance_type
  instance_type=$(aws ec2 describe-instance-types \
    --region "$region" \
    --filters \
      "Name=processor-info.supported-architecture,Values=$arch" \
      "Name=current-generation,Values=true" \
      "Name=instance-type,Values=t3.*,t4g.*,c5.*,m5.large,m5.xlarge" \
    --query 'InstanceTypes[*].{Type:InstanceType,VCpus:VCpuInfo.DefaultVCpus,Mem:MemoryInfo.SizeInMiB}' \
    --output json \
    | jq -r 'sort_by(.VCpus, .Mem) | .[0].Type')

  if [[ -z "$instance_type" || "$instance_type" == "null" ]]; then
    log_warn "Warning: Could not find instance type for arch $arch, using fallback"
    # Architecture-based fallback
    case "$arch" in
      arm64)   echo "t4g.micro" ;;
      x86_64)  echo "t3.micro" ;;
      *)       echo "t3.medium" ;;
    esac
    return 0
  fi

  log_success "Detected minimal instance type for $ami_id ($arch): $instance_type"
  echo "$instance_type"
}

if [[ $NODEGROUP_CONFIG = "custom-ami" ]]; then
  # custom ami name: "eks-lab-amazon-eks-arm64-1.29-20241023145809"
  export CUSTOM_AMI=$(aws ec2 describe-images \
    --filters "Name=name,Values=eks-lab*-1.29-*" "Name=state,Values=available" \
    --query 'Images[*].[ImageId,CreationDate]' \
    --output text \
    | sort -k2 -r \
    | head -n 1 \
    | awk '{print $1}')

  cat "$PROJECT_DIR/nodegroups/eksctl-managed-nodegroup-$NODEGROUP_CONFIG".yaml | envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${EKS_CLUSTER_REGION},${AZ_ARRAY},${NODEGROUP_CONFIG},${NODEGROUP_SIZE},${CUSTOM_AMI},${INSTANCE_TYPE}' > "$NODEGROUP_FILE"

elif [[ $NODEGROUP_CONFIG = "multi-ami" ]]; then
  # -----------------------------------------------------------------------
  # Multi-AMI: Each node group gets its own AMI and instance type.
  # -----------------------------------------------------------------------

  # --- Resolve AMIs ---
  if [[ -z "${CUSTOM_AMI_1:-}" || -z "${CUSTOM_AMI_2:-}" ]]; then
    log_info "Discovering AMIs matching pattern: eks-lab*-${CLUSTER_VERSION}-*"

    AMI_LIST=$(aws ec2 describe-images \
      --filters "Name=name,Values=eks-lab*-${CLUSTER_VERSION}-*" "Name=state,Values=available" \
      --query 'Images[*].[ImageId,CreationDate,Name]' \
      --output text \
      | sort -k2 -r)

    AMI_COUNT=$(echo "$AMI_LIST" | grep -c '^' || true)

    if [[ "$AMI_COUNT" -lt 2 ]]; then
      log_error "Error: Found only $AMI_COUNT AMI(s) matching the filter. Need at least 2."
      log_error "Either create more AMIs or export CUSTOM_AMI_1 and CUSTOM_AMI_2 manually."
      exit 1
    fi

    export CUSTOM_AMI_1=$(echo "$AMI_LIST" | sed -n '1p' | awk '{print $1}')
    export CUSTOM_AMI_2=$(echo "$AMI_LIST" | sed -n '2p' | awk '{print $1}')

    log_success "Discovered AMI 1: $CUSTOM_AMI_1"
    log_success "Discovered AMI 2: $CUSTOM_AMI_2"
  else
    log_success "Using pre-exported AMI 1: $CUSTOM_AMI_1"
    log_success "Using pre-exported AMI 2: $CUSTOM_AMI_2"
  fi

  # --- Resolve per-AMI instance types ---
  # Use pre-exported values, or auto-detect from AMI architecture
  if [[ -z "${INSTANCE_TYPE_1:-}" ]]; then
    log_info "Auto-detecting instance type for AMI 1: $CUSTOM_AMI_1"
    export NODEGROUP_SIZE_1=$(get_minimal_instance_type "$CUSTOM_AMI_1")
  else
    export NODEGROUP_SIZE_1="$INSTANCE_TYPE_1"
    log_success "Using pre-exported instance type 1: $NODEGROUP_SIZE_1"
  fi

  if [[ -z "${INSTANCE_TYPE_2:-}" ]]; then
    log_info "Auto-detecting instance type for AMI 2: $CUSTOM_AMI_2"
    export NODEGROUP_SIZE_2=$(get_minimal_instance_type "$CUSTOM_AMI_2")
  else
    export NODEGROUP_SIZE_2="$INSTANCE_TYPE_2"
    log_success "Using pre-exported instance type 2: $NODEGROUP_SIZE_2"
  fi

  # Validate per-AMI instance types
  if ! validate_instance_type "$NODEGROUP_SIZE_1"; then exit 1; fi
  if ! validate_instance_type "$NODEGROUP_SIZE_2"; then exit 1; fi

  # Instance type without dots (for nodegroup naming)
  export INSTANCE_TYPE_1="${NODEGROUP_SIZE_1//./}"
  export INSTANCE_TYPE_2="${NODEGROUP_SIZE_2//./}"

  log_success "Node group 1: AMI=$CUSTOM_AMI_1  Instance=$NODEGROUP_SIZE_1"
  log_success "Node group 2: AMI=$CUSTOM_AMI_2  Instance=$NODEGROUP_SIZE_2"

  cat "$PROJECT_DIR/nodegroups/eksctl-managed-nodegroup-$NODEGROUP_CONFIG".yaml | envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${EKS_CLUSTER_REGION},${AZ_ARRAY},${NODEGROUP_CONFIG},${NODEGROUP_SIZE_1},${NODEGROUP_SIZE_2},${CUSTOM_AMI_1},${CUSTOM_AMI_2},${INSTANCE_TYPE_1},${INSTANCE_TYPE_2},${API_SERVER_ENDPOINT},${CERTIFICATE_AUTHORITY},${SERVICE_CIDR}' > "$NODEGROUP_FILE"

elif [[ $NODEGROUP_CONFIG = "bottlerocket-userdata" ]]; then

  # https://github.com/bottlerocket-os/bottlerocket/blob/develop/QUICKSTART-EKS.md#cluster-info
  eksctl get cluster --region "$EKS_CLUSTER_REGION" --name "$EKS_CLUSTER_NAME" -o json \
   | jq --raw-output '.[] | "[settings.kubernetes]\napi-server = \"" + .Endpoint + "\"\ncluster-certificate =\"" + .CertificateAuthority.Data + "\"\ncluster-name = \"bottlerocket\""' > user-data.toml

  cat "$PROJECT_DIR/nodegroups/eksctl-managed-nodegroup-$NODEGROUP_CONFIG".yaml | envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${EKS_CLUSTER_REGION},${AZ_ARRAY},${NODEGROUP_CONFIG},${NODEGROUP_SIZE},${INSTANCE_TYPE}' > "$NODEGROUP_FILE"
else
  cat "$PROJECT_DIR/nodegroups/eksctl-managed-nodegroup-$NODEGROUP_CONFIG".yaml | envsubst '${EKS_CLUSTER_NAME},${CLUSTER_VERSION},${EKS_CLUSTER_REGION},${AZ_ARRAY},${NODEGROUP_CONFIG},${NODEGROUP_SIZE},${INSTANCE_TYPE},${API_SERVER_ENDPOINT},${CERTIFICATE_AUTHORITY},${SERVICE_CIDR}' > "$NODEGROUP_FILE"
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

if [[ $NODEGROUP_CONFIG = "multi-ami" ]]; then
  log_info "NG 1 Instance:       ${NODEGROUP_SIZE_1:-$NODEGROUP_SIZE}"
  log_info "NG 2 Instance:       ${NODEGROUP_SIZE_2:-$NODEGROUP_SIZE}"
else
  log_info "Nodegroup Size:      $NODEGROUP_SIZE"
fi
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
