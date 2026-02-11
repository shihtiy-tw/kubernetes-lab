#!/bin/bash

# Check if at least one argument is provided (Legacy Mode)
if [ $# -gt 0 ]; then
    # Set EKS_CLUSTER_NAME if provided
    if [ "$1" != "" ]; then
        # Only append prefix/suffix if it's a raw version number or base name
        if [[ "$1" =~ ^[0-9]+\.[0-9]+$ ]]; then
             # Legacy behavior: Version passed as arg 1 -> EKS-Lab-Version
             export CLUSTER_VERSION="$1"
             # Name will be constructed later
        else
             # Assume full name or base name provided
             EKS_CLUSTER_NAME="$1"
        fi
    fi

    # Set EKS_CLUSTER_REGION if provided
    if [ "$2" != "" ]; then
        EKS_CLUSTER_REGION="$2"
    fi
     # Set CLUSTER_CONFIG if provided
    if [ "$3" != "" ]; then
        case "$3" in
            full)
                CLUSTER_CONFIG="full"
                ;;
            minimal)
                CLUSTER_CONFIG="minimal"
                ;;
            auto)
                CLUSTER_CONFIG="auto"
                ;;
            # ipv6)
            #     CLUSTER_CONFIG="ipv6"
            #     ;;
            # private)
            #     CLUSTER_CONFIG="private"
            #     ;;
            *)
                echo "Invalid cluster configuration option. Exit the script. Please check if the cluster config is created or setup."
                exit
                ;;
        esac
    fi
fi

# Set default values if not provided (env vars take precedence)
export EKS_CLUSTER_REGION=${EKS_CLUSTER_REGION:-"us-east-1"}
export CLUSTER_CONFIG=${CLUSTER_CONFIG:-"minimal"}
export CLUSTER_VERSION="${CLUSTER_VERSION:-1.30}"
export CLUSTER_FILE_LOCATION="$(echo "$CLUSTER_VERSION"| sed 's/\./-/')"

# Construct name ONLY if not already set or detected
if [[ -z "${EKS_CLUSTER_NAME:-}" ]]; then
    export EKS_CLUSTER_NAME="EKS-Lab-${CLUSTER_FILE_LOCATION}-${CLUSTER_CONFIG}"
elif [[ "$EKS_CLUSTER_NAME" == "EKS-Lab-"* ]]; then
    # Already formatted, keep it
    :
elif [[ "$EKS_CLUSTER_NAME" == *"${CLUSTER_CONFIG}"* ]]; then
     # Config in name, keep it
    :
else
    # Append suffix if missing (legacy behavior helper) but usually safe to leave alone if user supplied it
    # We will trust the user provided name if it doesn't look like a raw version
    if [[ ! "$EKS_CLUSTER_NAME" =~ "EKS-Lab" ]]; then
         export EKS_CLUSTER_NAME="EKS-Lab-${CLUSTER_FILE_LOCATION}-${CLUSTER_CONFIG}"
    fi
fi

# Get AZs for the specified region if needed (usually handled by eksctl, but maybe used in templates)
# AZ_ARRAY is often environment dependent or fixed
# For now, we leave AZ_ARRAY logic as comment or rely on passed env vars
export AZ_ARRAY=${AZ_ARRAY:-"us-east-1a,us-east-1b,us-east-1c"}

echo "Configuring cluster $EKS_CLUSTER_NAME in region $EKS_CLUSTER_REGION"
