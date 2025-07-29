# AWS Load Balancer Controller Module

This module installs and configures the AWS Load Balancer Controller in an EKS cluster using Helm.

## Features

- ✅ **IRSA Integration**: Creates IAM role with OIDC provider for secure AWS API access
- ✅ **Helm Deployment**: Uses official AWS Load Balancer Controller Helm chart
- ✅ **Security Best Practices**: Minimal IAM permissions and pod security policies
- ✅ **High Availability**: Configurable replica count with pod disruption budgets
- ✅ **Resource Management**: Configurable CPU and memory limits/requests
- ✅ **Production Ready**: Comprehensive IAM policy covering all LB controller operations

## Prerequisites

1. **EKS Cluster**: Running EKS cluster with OIDC provider enabled
2. **IRSA Setup**: OIDC identity provider configured for the cluster
3. **Helm Provider**: Helm provider configured in your Terraform setup
4. **Kubernetes Provider**: Kubernetes provider configured with cluster access

## Usage

### Basic Usage

```hcl
module "aws_load_balancer_controller" {
  source = "../modules/aws-load-balancer-controller"

  cluster_name = "my-eks-cluster"
  aws_region   = "us-west-2"
  vpc_id       = "vpc-12345678"

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### Advanced Usage with Custom Configuration

```hcl
module "aws_load_balancer_controller" {
  source = "../modules/aws-load-balancer-controller"

  cluster_name           = "my-eks-cluster"
  aws_region            = "us-west-2"
  vpc_id                = "vpc-12345678"
  namespace             = "aws-load-balancer-system"
  create_namespace      = true
  helm_chart_version    = "1.8.1"
  replica_count         = 3

  # Resource tuning for production
  cpu_request    = "200m"
  cpu_limit      = "500m"
  memory_request = "300Mi"
  memory_limit   = "1Gi"

  # Additional Helm values
  additional_helm_values = [
    {
      name  = "enableShield"
      value = "true"
    },
    {
      name  = "enableWAFv2"
      value = "true"
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "my-project"
    Owner       = "platform-team"
  }
}
```

## Integration with EKS Module

```hcl
module "eks" {
  source = "../modules/eks"
  # ... EKS configuration ...
}

module "aws_load_balancer_controller" {
  source = "../modules/aws-load-balancer-controller"

  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
  vpc_id       = module.vpc.vpc_id

  # Ensure EKS cluster is ready before installing
  depends_on = [module.eks]

  tags = var.tags
}
```

## What This Module Creates

### AWS Resources
- **IAM Role**: For AWS Load Balancer Controller with IRSA
- **IAM Policy**: With comprehensive permissions for load balancer operations
- **IAM Policy Attachment**: Linking role and policy

### Kubernetes Resources
- **Namespace**: (Optional) Kubernetes namespace for the controller
- **ServiceAccount**: With IAM role annotation for IRSA
- **Helm Release**: AWS Load Balancer Controller deployment

## IAM Permissions

The module creates an IAM policy with the following permissions:
- **EC2**: VPC, subnet, security group, and instance management
- **ELBv2**: Application and Network Load Balancer operations
- **Route53**: DNS record management for ALB ingress
- **ACM**: Certificate discovery and management
- **WAF/WAFv2**: Web ACL association
- **Shield**: DDoS protection management
- **Cognito**: User pool integration for ALB authentication

## Post-Installation

After deployment, you can create ALB ingress resources:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

## Troubleshooting

### Common Issues

1. **OIDC Provider Not Found**
   - Ensure OIDC provider is enabled on EKS cluster
   - Verify OIDC issuer URL matches in trust policy

2. **Insufficient Permissions**
   - Check IAM role has all required permissions
   - Verify service account annotation with correct role ARN

3. **Helm Chart Installation Fails**
   - Ensure Helm provider is configured correctly
   - Check cluster connectivity and permissions

### Verification

```bash
# Check controller pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify webhook configuration
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations
```

## Version Compatibility

| Component | Version |
|-----------|---------|
| AWS Load Balancer Controller | 1.8.1 |
| Kubernetes | >= 1.28 |
| Helm Chart | >= 1.8.0 |
| Terraform | >= 1.0 |
| AWS Provider | >= 6.0 |

## Security Considerations

- ✅ **Minimal IAM Permissions**: Only required permissions for LB operations
- ✅ **IRSA Security**: No long-lived AWS credentials in pods
- ✅ **Pod Security**: Restricted pod security policies
- ✅ **Network Policies**: Can be configured for additional network isolation
- ✅ **Resource Limits**: Prevents resource exhaustion

## Cost Optimization

- Uses efficient resource requests/limits
- Supports horizontal pod autoscaling
- Creates load balancers only when needed via ingress resources

## Contributing

When modifying this module:
1. Update IAM permissions if new AWS services are required
2. Test with different EKS versions
3. Validate Helm chart version compatibility
4. Update documentation for new features
