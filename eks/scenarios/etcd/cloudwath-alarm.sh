#!/usr/bin/env bash
# ETCD CloudWatch Alarm Scenario
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

Create CloudWatch alarm for ETCD storage size monitoring.

OPTIONS:
    --cluster NAME        EKS cluster name (default: from context)
    --region REGION       AWS region (default: from context)
    --sns-topic ARN       SNS topic ARN for alarm notifications
    --threshold GB        Storage threshold in GB (default: 6)
    --alarm-name NAME     Alarm name (default: EKS-ETCD-Storage-Size-Alarm)
    --dry-run             Show what would be created
    --delete              Delete the alarm
    -h, --help            Show this help message
    -v, --version         Show script version

EXAMPLES:
    # Create alarm with SNS notification
    $(basename "$0") --sns-topic arn:aws:sns:us-east-1:123456789:my-topic

    # Create alarm with custom threshold
    $(basename "$0") --threshold 8 --sns-topic arn:aws:sns:us-east-1:123456789:my-topic

    # Dry run
    $(basename "$0") --sns-topic arn:aws:sns:us-east-1:123456789:my-topic --dry-run

    # Delete alarm
    $(basename "$0") --delete
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
CLUSTER_NAME=""
REGION=""
SNS_TOPIC=""
THRESHOLD_GB=6
ALARM_NAME="EKS-ETCD-Storage-Size-Alarm"
DRY_RUN=false
DELETE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --sns-topic)
            SNS_TOPIC="$2"
            shift 2
            ;;
        --threshold)
            THRESHOLD_GB="$2"
            shift 2
            ;;
        --alarm-name)
            ALARM_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --delete)
            DELETE=true
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

# Get cluster info
get_cluster_info() {
    if [[ -z "$CLUSTER_NAME" ]] || [[ -z "$REGION" ]]; then
        local context
        context=$(kubectl config current-context)
        
        [[ -z "$CLUSTER_NAME" ]] && CLUSTER_NAME=$(echo "$context" | awk -F: '{split($NF,a,"/"); print a[2]}')
        [[ -z "$REGION" ]] && REGION=$(echo "$context" | awk -F: '{print $4}')
    fi
}

# Main
main() {
    get_cluster_info

    log_step "Environment"
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $REGION"
    log_info "Alarm Name: $ALARM_NAME"
    log_info "Threshold: ${THRESHOLD_GB}GB"

    if $DELETE; then
        log_step "Deleting Alarm"
        if $DRY_RUN; then
            log_info "[DRY RUN] Would delete alarm: $ALARM_NAME"
            exit 0
        fi
        
        aws cloudwatch delete-alarms --alarm-names "$ALARM_NAME" --region "$REGION"
        log_success "Alarm deleted"
        exit 0
    fi

    if [[ -z "$SNS_TOPIC" ]]; then
        log_error "--sns-topic is required for alarm notifications"
        echo "Run '$(basename "$0") --help' for usage." >&2
        exit 1
    fi
    log_info "SNS Topic: $SNS_TOPIC"

    # Calculate threshold in bytes
    local threshold_bytes
    threshold_bytes=$((THRESHOLD_GB * 1000000000))

    if $DRY_RUN; then
        log_step "Dry Run Summary"
        log_info "Would create alarm: $ALARM_NAME"
        log_info "Metric: apiserver_storage_size_bytes"
        log_info "Threshold: $threshold_bytes bytes (${THRESHOLD_GB}GB)"
        log_info "Evaluation Periods: 3"
        exit 0
    fi

    log_step "Creating CloudWatch Alarm"
    aws cloudwatch put-metric-alarm \
        --alarm-name "$ALARM_NAME" \
        --alarm-description "Alarm when ETCD storage size exceeds ${THRESHOLD_GB}GB" \
        --metric-name "apiserver_storage_size_bytes" \
        --namespace "ContainerInsights" \
        --statistic "Maximum" \
        --period 60 \
        --threshold "$threshold_bytes" \
        --comparison-operator "GreaterThanThreshold" \
        --dimensions "Name=ClusterName,Value=$CLUSTER_NAME" \
        --evaluation-periods 3 \
        --alarm-actions "$SNS_TOPIC" \
        --unit "Bytes" \
        --region "$REGION"

    log_success "Alarm created"

    log_step "Complete"
    log_info "ETCD storage alarm configured for $CLUSTER_NAME"
    log_info "Verify: aws cloudwatch describe-alarms --alarm-names $ALARM_NAME"
    exit 0
}

main "$@"
