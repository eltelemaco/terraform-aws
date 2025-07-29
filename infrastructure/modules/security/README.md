# AWS EKS Security Module

This module provides comprehensive security configurations for AWS EKS infrastructure, implementing security best practices and compliance requirements.

## Features

### Security Groups
- **EKS Cluster Security Group**: Additional security group for EKS control plane with fine-grained access control
- **EKS Node Security Group**: Security group for worker nodes with node-to-node and control plane communication
- **Load Balancer Security Group**: Security group for ALB/NLB with HTTP/HTTPS access controls
- **Database Security Group**: Optional security group for RDS databases with restricted access from EKS nodes
- **EFS Security Group**: Optional security group for EFS file systems with NFS access from nodes

### Encryption & Key Management
- **KMS Key**: Dedicated KMS key for EKS cluster encryption with automatic rotation
- **KMS Key Policy**: Fine-grained access control for encryption keys
- **Secrets Manager Integration**: Support for encrypted secrets management

### Network Security
- **Network ACLs**: Additional subnet-level protection for private subnets
- **VPC Flow Logs**: Network traffic monitoring and logging
- **Network Isolation**: Strict network segmentation policies

### Web Application Firewall
- **AWS WAF v2**: Protection against common web exploits and attacks
- **Managed Rule Sets**: AWS managed rules for common attack patterns
- **Rate Limiting**: Configurable rate limiting to prevent abuse
- **Custom Rules**: Support for custom security rules

### Threat Detection
- **GuardDuty**: Threat detection with Kubernetes audit log analysis
- **Malware Protection**: EC2 instance scanning for malware
- **S3 Protection**: S3 bucket threat detection

### Compliance Features
- **IMDSv2 Enforcement**: Instance Metadata Service v2 enforcement
- **EBS Encryption**: Default encryption for EBS volumes
- **Pod Security Policies**: Kubernetes pod security enforcement
- **Network Policies**: Kubernetes network micro-segmentation

## Usage

### Basic Configuration

```hcl
module "security" {
  source = "./modules/security"
  
  cluster_name = "my-eks-cluster"
  environment  = "prod"
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = "10.0.0.0/16"
  
  # API server access from office network
  api_server_access_cidrs = ["203.0.113.0/24"]
  
  tags = {
    Project     = "EKS Infrastructure"
    Environment = "production"
    Terraform   = "true"
  }
}
```

### Advanced Configuration with All Features

```hcl
module "security" {
  source = "./modules/security"
  
  cluster_name        = "my-eks-cluster"
  environment         = "prod"
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = "10.0.0.0/16"
  private_subnet_ids  = module.vpc.private_subnets
  
  # Security Groups
  create_load_balancer_sg = true
  create_database_sg      = true
  create_efs_sg          = true
  
  # Network Security
  api_server_access_cidrs = ["203.0.113.0/24", "198.51.100.0/24"]
  create_network_acl      = true
  enable_network_isolation = true
  
  # Encryption
  create_kms_key                     = true
  enable_kms_key_rotation           = true
  kms_key_deletion_window_in_days   = 7
  kms_key_administrators            = ["arn:aws:iam::123456789012:user/admin"]
  
  # WAF Protection
  create_waf_acl   = true
  waf_rate_limit   = 2000
  
  # Threat Detection
  enable_guardduty              = true
  guardduty_finding_frequency   = "SIX_HOURS"
  
  # Monitoring
  enable_flow_logs             = true
  flow_log_destination_type    = "cloud-watch-logs"
  flow_log_retention_in_days   = 30
  
  # Compliance
  enforce_imdsv2              = true
  block_device_encrypted      = true
  enable_pod_security_policy  = true
  enable_network_policies     = true
  
  # Secrets Management
  enable_secrets_rotation = true
  
  # Additional Load Balancer Rules
  additional_ingress_rules = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Custom application port"
      cidr_blocks = "10.0.0.0/16"
    }
  ]
  
  tags = {
    Project     = "EKS Infrastructure"
    Environment = "production"
    Terraform   = "true"
    Compliance  = "SOC2"
  }
}
```

### Integration with EKS Module

```hcl
module "security" {
  source = "./modules/security"
  
  cluster_name = var.cluster_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr_block
  
  create_kms_key = true
  enable_guardduty = true
  
  tags = var.tags
}

module "eks" {
  source = "./modules/eks"
  
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
  
  # Use security module outputs
  additional_security_group_ids = [
    module.security.eks_cluster_security_group_id
  ]
  
  encryption_config = {
    provider_key_arn = module.security.kms_key_arn
    resources        = ["secrets"]
  }
  
  tags = var.tags
}
```

## Security Best Practices

### Network Security
1. **Private Subnets**: Deploy EKS nodes in private subnets only
2. **API Server Access**: Restrict API server access to known CIDR blocks
3. **Security Groups**: Use least-privilege security group rules
4. **Network ACLs**: Implement additional subnet-level protection
5. **VPC Flow Logs**: Enable comprehensive network monitoring

### Encryption
1. **Envelope Encryption**: Use customer-managed KMS keys
2. **Key Rotation**: Enable automatic key rotation
3. **EBS Encryption**: Encrypt all EBS volumes
4. **Secrets Manager**: Use AWS Secrets Manager for sensitive data
5. **In-Transit Encryption**: Ensure all communications use TLS

### Access Control
1. **IAM Roles**: Use IAM roles for service accounts (IRSA)
2. **Least Privilege**: Implement minimal required permissions
3. **MFA**: Require multi-factor authentication for admin access
4. **Access Entries**: Use EKS access entries instead of ConfigMap
5. **Pod Security**: Implement Pod Security Standards

### Monitoring & Logging
1. **GuardDuty**: Enable for threat detection
2. **CloudTrail**: Log all API calls
3. **Container Insights**: Monitor EKS cluster performance
4. **Audit Logs**: Enable EKS audit logging
5. **Flow Logs**: Monitor network traffic

### Compliance
1. **CIS Benchmarks**: Follow CIS Kubernetes Benchmark
2. **Pod Security Standards**: Implement Kubernetes Pod Security Standards
3. **Network Policies**: Use Kubernetes Network Policies
4. **Image Scanning**: Scan container images for vulnerabilities
5. **Regular Audits**: Perform regular security assessments

## Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Internet Gateway                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                  WAF Web ACL                               │
│  ├─ Common Rule Set                                        │
│  ├─ Known Bad Inputs                                       │
│  └─ Rate Limiting                                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              Application Load Balancer                     │
│              (ALB Security Group)                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                  Public Subnets                           │
│              (Network ACL Rules)                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 Private Subnets                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              EKS Control Plane                     │   │
│  │         (Cluster Security Group)                   │   │
│  └─────────────────┬───────────────────────────────────┘   │
│                    │                                       │
│  ┌─────────────────▼───────────────────────────────────┐   │
│  │              EKS Worker Nodes                      │   │
│  │          (Node Security Group)                     │   │
│  │                                                    │   │
│  │  ├─ Pod Security Policies                          │   │
│  │  ├─ Network Policies                               │   │
│  │  └─ IRSA (IAM Roles for Service Accounts)          │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 Data Layer                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              RDS Database                           │   │
│  │         (Database Security Group)                   │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                EFS Storage                          │   │
│  │          (EFS Security Group)                       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                Security & Monitoring                       │
│  ├─ KMS Key (Customer Managed)                             │
│  ├─ GuardDuty (Threat Detection)                           │
│  ├─ VPC Flow Logs                                          │
│  ├─ CloudTrail (API Logging)                               │
│  └─ AWS Config (Compliance)                                │
└─────────────────────────────────────────────────────────────┘
```

## Compliance Mapping

### SOC 2 Type II
- ✅ **Availability**: GuardDuty, monitoring, and alerting
- ✅ **Security**: Encryption, access controls, network security
- ✅ **Confidentiality**: KMS encryption, secrets management
- ✅ **Processing Integrity**: Audit logging, immutable infrastructure

### CIS Controls
- ✅ **Control 3**: Data Protection
- ✅ **Control 6**: Access Control Management  
- ✅ **Control 8**: Malware Defenses
- ✅ **Control 12**: Network Security
- ✅ **Control 14**: Controlled Access Based on Need to Know

### NIST Cybersecurity Framework
- ✅ **Identify**: Asset management, risk assessment
- ✅ **Protect**: Access control, data security
- ✅ **Detect**: Continuous monitoring, threat detection
- ✅ **Respond**: Incident response procedures
- ✅ **Recover**: Backup and recovery procedures

## Cost Considerations

| Component | Estimated Monthly Cost | Notes |
|-----------|----------------------|--------|
| KMS Key | ~$1 | $1/month per key + usage |
| GuardDuty | ~$4-50 | Based on data processed |
| WAF | ~$5-20 | Based on requests processed |
| VPC Flow Logs | ~$3-15 | Based on log volume |
| Network ACLs | Free | No additional charges |
| Security Groups | Free | No additional charges |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_id | ID of the VPC where security groups will be created | `string` | n/a | yes |
| vpc_cidr | CIDR block of the VPC | `string` | n/a | yes |
| api_server_access_cidrs | List of CIDR blocks that can access the EKS API server | `list(string)` | `["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]` | no |
| create_load_balancer_sg | Whether to create security group for load balancers | `bool` | `true` | no |
| create_database_sg | Whether to create security group for databases | `bool` | `false` | no |
| create_efs_sg | Whether to create security group for EFS | `bool` | `false` | no |
| create_kms_key | Whether to create KMS key for EKS encryption | `bool` | `true` | no |
| enable_guardduty | Whether to enable GuardDuty for threat detection | `bool` | `false` | no |
| create_waf_acl | Whether to create WAF Web ACL for ALB protection | `bool` | `false` | no |
| enable_flow_logs | Whether to enable VPC Flow Logs for security monitoring | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| eks_cluster_security_group_id | ID of the EKS cluster additional security group |
| eks_node_security_group_id | ID of the EKS node additional security group |
| load_balancer_security_group_id | ID of the load balancer security group |
| kms_key_arn | ARN of the KMS key for EKS encryption |
| compliance_status | Compliance status based on security configurations |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| eks_cluster_security_group | terraform-aws-modules/security-group/aws | ~> 5.3 |
| eks_node_security_group | terraform-aws-modules/security-group/aws | ~> 5.3 |
| load_balancer_security_group | terraform-aws-modules/security-group/aws | ~> 5.3 |
| database_security_group | terraform-aws-modules/security-group/aws | ~> 5.3 |
| efs_security_group | terraform-aws-modules/security-group/aws | ~> 5.3 |

## License

This module is licensed under the MIT License. See [LICENSE](LICENSE) for full details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Support

For questions or issues, please open an issue in the repository or contact the infrastructure team.
