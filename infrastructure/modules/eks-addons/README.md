# EKS Blueprints Addons Module

This Terraform module provides enterprise-grade EKS addons using the official AWS EKS Blueprints Addons module. It deploys essential Kubernetes addons for production workloads including core AWS services, autoscaling, security, and observability components.

## Features

### Core EKS Add-ons (AWS Managed)
- **AWS EBS CSI Driver**: Persistent storage management
- **CoreDNS**: Cluster DNS resolution with Fargate optimization
- **VPC CNI**: Advanced pod networking with prefix delegation
- **Kube-proxy**: Service networking and load balancing

### Infrastructure Add-ons
- **AWS Load Balancer Controller**: Application and Network Load Balancer integration
- **Metrics Server**: Resource metrics for HPA and monitoring
- **Cluster Autoscaler**: Automatic node scaling based on demand
- **AWS EFS CSI Driver**: Shared storage across multiple pods/nodes

### Security & Compliance
- **cert-manager**: Automatic TLS certificate management
- **External Secrets Operator**: Secure secret management from AWS services
- **Vertical Pod Autoscaler**: Resource optimization recommendations

### Advanced Features
- **External DNS**: Automatic DNS record management
- **Karpenter**: Advanced node provisioning and optimization
- **AWS for FluentBit**: Log forwarding to CloudWatch

## Usage

```hcl
module "eks_addons" {
  source = "./modules/eks-addons"

  # Cluster information
  cluster_name      = "my-eks-cluster"
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = "1.31"
  oidc_provider_arn = module.eks.oidc_provider_arn
  aws_region        = "us-west-2"

  # Core EKS addons (recommended for all clusters)
  enable_core_addons = true

  # Essential production addons
  enable_metrics_server      = true
  enable_cluster_autoscaler  = true

  # AWS Load Balancer Controller (if not using separate module)
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller_config = {
    chart_version            = "1.8.1"
    replicas                = 2
    log_level              = "info"
    service_account_role_arn = module.iam_roles.alb_controller_role_arn
  }

  # Security addons
  enable_cert_manager = true
  cert_manager_config = {
    chart_version            = "v1.15.3"
    service_account_role_arn = module.iam_roles.cert_manager_role_arn
  }

  enable_external_secrets = true
  external_secrets_config = {
    chart_version            = "0.10.2"
    service_account_role_arn = module.iam_roles.external_secrets_role_arn
  }

  # Optional: Advanced node management
  enable_karpenter = false  # Set to true for advanced node provisioning
  karpenter_config = {
    chart_version             = "1.0.1"
    service_account_role_arn  = module.iam_roles.karpenter_role_arn
    node_instance_profile     = module.iam_roles.karpenter_node_instance_profile
    interruption_queue_name   = "my-cluster-karpenter"
  }

  # Optional: Resource optimization
  enable_vpa = true
  vpa_config = {
    chart_version = "4.6.0"
  }

  # Optional: DNS management
  enable_external_dns = true
  external_dns_config = {
    chart_version            = "1.14.5"
    service_account_role_arn = module.iam_roles.external_dns_role_arn
    domain_filter           = "example.com"
  }

  # Optional: Shared storage
  enable_aws_efs_csi_driver = false
  aws_efs_csi_driver_config = {
    chart_version            = "3.0.8"
    service_account_role_arn = module.iam_roles.efs_csi_role_arn
  }

  # Optional: Log forwarding
  enable_aws_for_fluentbit = true
  aws_for_fluentbit_config = {
    chart_version            = "0.1.32"
    service_account_role_arn = module.iam_roles.fluentbit_role_arn
    log_group_name          = "/aws/eks/${var.cluster_name}/logs"
  }

  tags = {
    Environment = "production"
    Project     = "terraform-aws"
    ManagedBy   = "terraform"
  }
}
```

## Recommended Configurations

### Minimal Production Setup
```hcl
# Essential addons for any production cluster
enable_core_addons         = true
enable_metrics_server      = true
enable_cluster_autoscaler  = true
enable_cert_manager        = true
```

### Standard Production Setup
```hcl
# Comprehensive production setup
enable_core_addons                     = true
enable_metrics_server                  = true
enable_cluster_autoscaler             = true
enable_aws_load_balancer_controller   = true
enable_cert_manager                   = true
enable_external_secrets               = true
enable_vpa                           = true
enable_aws_for_fluentbit             = true
```

### Advanced Production Setup
```hcl
# Full enterprise setup with advanced features
enable_core_addons                     = true
enable_metrics_server                  = true
enable_cluster_autoscaler             = true
enable_aws_load_balancer_controller   = true
enable_cert_manager                   = true
enable_external_secrets               = true
enable_external_dns                   = true
enable_vpa                           = true
enable_karpenter                     = true
enable_aws_efs_csi_driver            = true
enable_aws_for_fluentbit             = true
```

## IAM Requirements

Each addon requires specific IAM roles with appropriate permissions. Ensure you have the following IAM roles created:

### Required Service Account Roles
- **AWS Load Balancer Controller**: `AWSLoadBalancerControllerIAMPolicy`
- **Cluster Autoscaler**: EC2 and Auto Scaling permissions
- **External DNS**: Route53 permissions
- **External Secrets**: Secrets Manager/SSM permissions
- **cert-manager**: Route53 permissions (for DNS-01 challenges)
- **EBS CSI Driver**: EBS volume permissions
- **EFS CSI Driver**: EFS permissions
- **VPC CNI**: EC2 and VPC permissions
- **Karpenter**: EC2, Auto Scaling, and SSM permissions
- **AWS for FluentBit**: CloudWatch Logs permissions

## Outputs

The module provides comprehensive outputs for monitoring and integration:

```hcl
# Get addon deployment status
output "addon_summary" {
  value = module.eks_addons.addon_summary
}

# Get service account role ARNs
output "service_account_roles" {
  value = module.eks_addons.service_account_role_arns
}

# Get namespaces created
output "addon_namespaces" {
  value = module.eks_addons.namespaces_created
}
```

## Version Compatibility

| Component | Version | EKS Version | Notes |
|-----------|---------|-------------|-------|
| EBS CSI Driver | v1.35.0 | 1.31+ | Latest stable |
| CoreDNS | v1.11.1 | 1.31+ | Fargate optimized |
| VPC CNI | v1.18.5 | 1.31+ | Prefix delegation enabled |
| Kube-proxy | v1.31.0 | 1.31+ | Matches cluster version |
| ALB Controller | 1.8.1 | 1.19+ | Latest stable |
| Metrics Server | 3.12.1 | 1.19+ | Latest stable |
| Cluster Autoscaler | 9.37.0 | 1.31+ | Version matched |
| cert-manager | v1.15.3 | 1.22+ | Latest stable |
| Karpenter | 1.0.1 | 1.23+ | Latest stable |

## Troubleshooting

### Common Issues

1. **Service Account Role ARN Missing**
   ```
   Error: service account role ARN is required for addon X
   ```
   Solution: Ensure all required IAM roles are created and role ARNs are provided.

2. **Namespace Already Exists**
   ```
   Error: namespace "cert-manager" already exists
   ```
   Solution: Import existing namespace or disable namespace creation.

3. **Addon Version Compatibility**
   ```
   Error: addon version X is not compatible with EKS version Y
   ```
   Solution: Check version compatibility matrix and update versions.

### Debugging Commands

```bash
# Check addon status
kubectl get pods -A | grep -E "(cert-manager|external-secrets|karpenter)"

# Check service accounts
kubectl get serviceaccounts -A | grep -E "(aws-load-balancer|cluster-autoscaler)"

# Check CRDs installed
kubectl get crds | grep -E "(certificates|secretstores|nodeclaims)"

# Check logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
kubectl logs -n cert-manager deployment/cert-manager
```

## Security Considerations

1. **Least Privilege**: Each addon uses dedicated IAM roles with minimal required permissions
2. **Network Policies**: Configure network policies to restrict pod-to-pod communication
3. **Pod Security Standards**: Namespaces are configured with restricted pod security standards
4. **Resource Limits**: All addons have resource limits to prevent resource exhaustion
5. **Update Management**: Keep addon versions updated for security patches

## Cost Optimization

- **Cluster Autoscaler**: Automatically scales nodes based on demand
- **VPA**: Optimizes pod resource requests and limits
- **Karpenter**: Advanced node provisioning with spot instance support
- **Resource Limits**: Prevents resource over-allocation

## Support

For issues and questions:
- Check AWS EKS documentation for addon-specific guidance
- Review Kubernetes addon documentation
- Monitor CloudWatch logs for addon-specific errors
- Use `kubectl describe` commands for detailed status information
