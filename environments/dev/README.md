# Development Environment

This directory contains the Terraform configuration for the development environment.

## Overview

This configuration creates:
- A VPC with public and private subnets across multiple availability zones
- An EKS cluster with managed node groups
- All necessary networking components (NAT gateways, internet gateway, route tables)
- CloudWatch logging and monitoring
- IAM roles and security groups

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform** (>= 1.0) installed
3. **kubectl** installed for cluster management
4. **Proper IAM permissions** for creating EKS clusters and VPC resources

## Quick Start

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars** with your specific values:
   - Update AWS region if needed
   - Adjust CIDR blocks to avoid conflicts
   - Configure cluster settings
   - Add your access entries for cluster access

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan the deployment:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

6. **Configure kubectl:**
   ```bash
   aws eks --region us-west-2 update-kubeconfig --name dev-eks-cluster
   ```

## Configuration Files

| File | Purpose |
|------|---------|
| `main.tf` | Main configuration orchestrating VPC and EKS modules |
| `variables.tf` | Variable definitions with defaults |
| `outputs.tf` | Output values for resources created |
| `terraform.tfvars.example` | Example configuration values |

## Key Features

### VPC Configuration
- **CIDR**: 10.0.0.0/16 (configurable)
- **Subnets**: Public, private, database, elasticache, and intra subnets
- **NAT Gateways**: One per AZ for high availability
- **Flow Logs**: Enabled for network monitoring

### EKS Configuration
- **Kubernetes Version**: 1.31 (configurable)
- **Node Groups**: Managed node groups with auto-scaling
- **Addons**: CoreDNS, kube-proxy, VPC CNI, EBS CSI driver
- **Logging**: API, audit, and authenticator logs enabled
- **Authentication**: API_AND_CONFIG_MAP mode for flexibility

### Security Features
- **Network isolation** with private subnets for worker nodes
- **Security groups** with minimal required access
- **IAM roles** following least privilege principle
- **Encryption** options for EKS secrets (configurable)

## Customization

### Scaling Configuration
- Adjust `min_size`, `max_size`, and `desired_size` in node groups
- Modify `instance_types` based on workload requirements
- Consider using SPOT instances for cost optimization

### Network Configuration
- Update CIDR blocks to match your network design
- Configure endpoint access based on security requirements
- Adjust NAT gateway configuration for cost optimization

### Cost Optimization for Development
- Use `single_nat_gateway = true` to reduce costs
- Consider SPOT instances for node groups
- Reduce log retention periods
- Disable KMS encryption if not required

## Monitoring and Troubleshooting

### Viewing Logs
```bash
# EKS cluster logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks/dev-eks-cluster

# VPC Flow Logs
aws logs describe-log-groups --log-group-name-prefix /aws/vpc/flowlogs
```

### Cluster Access
```bash
# Verify cluster access
kubectl cluster-info

# List nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

### Common Issues
1. **Insufficient IAM permissions**: Ensure your AWS credentials have EKS and EC2 full access
2. **VPC CIDR conflicts**: Make sure CIDR blocks don't overlap with existing networks
3. **Quota limits**: Check AWS service quotas for EKS clusters and EC2 instances

## Cleanup

To destroy the environment:

```bash
terraform destroy
```

**Warning**: This will delete all resources including the EKS cluster and VPC. Make sure to backup any important data first.

## Security Considerations

### For Development Environment
- Public endpoint access is enabled for convenience
- Consider restricting `endpoint_public_access_cidrs` to your IP ranges
- Use least privilege IAM policies
- Regularly update Kubernetes version and node AMIs

### Access Management
- Add team members through `access_entries` variable
- Use AWS IAM Identity Center for centralized access management
- Consider using RBAC for fine-grained Kubernetes permissions

## Next Steps

After successful deployment:
1. Install cluster autoscaler
2. Set up ingress controller (AWS Load Balancer Controller is included)
3. Configure monitoring with Prometheus/Grafana
4. Set up CI/CD pipelines for application deployment

## Support

For issues related to:
- **AWS resources**: Check AWS documentation and CloudTrail logs
- **Terraform**: Review Terraform state and plan output
- **Kubernetes**: Use kubectl for cluster debugging
- **Modules**: Refer to module documentation in `../../modules/`
