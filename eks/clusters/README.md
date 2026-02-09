# EKS Clusters & Resources

This directory contains configuration files and templates for EKS clusters, nodegroups, launch templates, and other resources. These files serve as reference implementations and starting points for creating and managing EKS infrastructure.

## Directory Structure

```
clusters/
├── launch-templates/ # EC2 launch templates for EKS nodes
├── usecases/         # Specific implementation patterns
├── versions/         # Version-specific configurations
└── create.sh         # Cluster creation script
```

## Key Components

### Clusters

The cluster configuration files (e.g., `eksctl-cluster-minimal.yaml`) provide example settings for creating EKS clusters with different features. These examples demonstrate:

- Cluster creation with eksctl
- Custom networking configurations
- Control plane logging options
- Cluster add-on configurations

### Launch Templates

The `launch-templates` directory contains EC2 launch template configurations for EKS nodes, including:

- AL2023 optimized templates
- Custom user data scripts
- Instance type selections
- Storage configurations

### Usecases

The `usecases` directory provides specialized implementation patterns, such as cross-VPC load balancing.

## Usage

### Creating a Cluster

You can use the `create.sh` script to create a cluster:

```bash
./create.sh --name my-cluster --region us-west-2
```

Or use `eksctl` directly with the provided configuration files:

```bash
eksctl create cluster -f eksctl-cluster-minimal.yaml
```

## Best Practices

When working with EKS resources:

1. Always use Infrastructure as Code (IaC) to define and manage resources
2. Follow the principle of least privilege for IAM roles and policies
3. Use tagging for resource organization and cost allocation
4. Consider using managed nodegroups for simplified operations
5. Implement proper networking and security configurations

## Prerequisites

Before creating EKS resources:

1. Install required tools as documented in the [root README](../../README.md)
2. Configure AWS credentials with appropriate permissions
3. Understand the AWS and Kubernetes resource model
4. Plan your networking and security requirements
