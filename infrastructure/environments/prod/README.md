# Production Environment - README

## 🏭 Production Environment Overview

This directory contains the **production-ready** Terraform configuration for deploying enterprise-grade AWS infrastructure with EKS Kubernetes clusters, advanced security controls, and comprehensive observability.

## 🎯 Production Features

### 🛡️ Enterprise Security
- **KMS Encryption**: Full encryption for cluster and volumes with automatic key rotation
- **VPC Flow Logs**: Network traffic monitoring and security analysis
- **Private Subnets**: Worker nodes in private subnets with no direct internet access
- **Multi-AZ NAT Gateways**: High availability NAT gateways across 3 availability zones
- **Security Groups**: Layered network security with least privilege access
- **RBAC Integration**: Kubernetes role-based access control with IRSA

### 📈 High Availability & Scalability
- **Multi-AZ Deployment**: Resources distributed across 3 availability zones
- **Auto Scaling**: Cluster Autoscaler + Karpenter for intelligent node management
- **Load Balancing**: AWS Load Balancer Controller with 3 replicas for high availability
- **Mixed Instance Types**: Cost optimization with on-demand and spot instances
- **Horizontal/Vertical Scaling**: HPA and VPA for workload optimization

### 🔍 Advanced Observability
- **Comprehensive Logging**: 5 EKS log types with 90-day retention
- **Metrics Collection**: Metrics Server for resource monitoring
- **Log Processing**: FluentBit for advanced log aggregation
- **External DNS**: Automated DNS record management
- **Certificate Management**: cert-manager for TLS automation

### 🚀 Production Addons Ecosystem
- **AWS Load Balancer Controller**: ALB/NLB provisioning and management
- **Cluster Autoscaler**: Traditional node scaling based on resource requests
- **Karpenter**: Just-in-time node provisioning with cost optimization
- **cert-manager**: Automated TLS certificate lifecycle management
- **External Secrets Operator**: Secure integration with AWS Secrets Manager
- **Vertical Pod Autoscaler**: Right-sizing recommendations and automation
- **EFS CSI Driver**: Persistent storage for stateful applications
- **External DNS**: Automated DNS record management for services

## 📋 Prerequisites

### 🔧 Required Tools
```bash
# Core tools
terraform >= 1.0
aws-cli >= 2.0
kubectl >= 1.28

# Verification
terraform version
aws --version
kubectl version --client
```

### 🎫 AWS Permissions
The deploying user/role needs comprehensive permissions:
- **EC2**: VPC, Subnet, Security Group, NAT Gateway management
- **EKS**: Cluster creation, node groups, addons management
- **IAM**: Role and policy creation for service accounts
- **KMS**: Key creation and management for encryption
- **CloudWatch**: Log group creation and management
- **Route53**: DNS record management (if using External DNS)

### 🏗️ Infrastructure Dependencies
- **S3 Bucket**: For Terraform remote state storage
- **DynamoDB Table**: For Terraform state locking
- **Route53 Hosted Zone**: For DNS management (optional)

## 🚀 Deployment Instructions

### 1️⃣ Configure Remote State Backend

Update the backend configuration in `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-prod-secure"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-west-2:ACCOUNT:key/KEY-ID"
    dynamodb_table = "terraform-state-lock-prod"
  }
}
```

### 2️⃣ Configure Variables

Create `terraform.tfvars` from the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

**Critical Production Variables:**
```hcl
# Basic Configuration
aws_region = "us-west-2"
environment = "prod"
cluster_name = "prod-eks-cluster"

# Network Configuration
vpc_cidr = "10.2.0.0/16"
private_subnets = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
public_subnets  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]

# High Availability Settings
one_nat_gateway_per_az = true
enable_nat_gateway = true

# Security Settings
endpoint_private_access = true
endpoint_public_access = true
endpoint_public_access_cidrs = ["YOUR-OFFICE-IP/32"]

# Production Node Groups
eks_managed_node_groups = {
  prod_general = {
    instance_types = ["m5.xlarge", "m5.2xlarge"]
    capacity_type = "ON_DEMAND"
    min_size = 3
    max_size = 20
    desired_size = 6
  }
  prod_compute = {
    instance_types = ["c5.2xlarge", "c5.4xlarge"]
    capacity_type = "ON_DEMAND"
    min_size = 2
    max_size = 10
    desired_size = 3
  }
}

# Logging Configuration
enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cloudwatch_log_group_retention_in_days = 90

# Encryption
create_kms_key = true
enable_kms_key_rotation = true

# Application Configuration
dagster_s3_bucket_name = "your-dagster-prod-bucket"
dagster_replicas = 3
```

### 3️⃣ Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="terraform.tfvars"

# Deploy infrastructure (PRODUCTION - Use with caution)
terraform apply -var-file="terraform.tfvars"
```

### 4️⃣ Configure kubectl

```bash
# Update kubeconfig
aws eks --region us-west-2 update-kubeconfig --name prod-eks-cluster

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

### 5️⃣ Verify Deployments

```bash
# Check EKS addons
kubectl get pods -n kube-system

# Check Dagster deployment
kubectl get pods -n dagster

# Check ingress controllers
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check cert-manager
kubectl get pods -n cert-manager

# Check external-secrets
kubectl get pods -n external-secrets
```

## 🔍 Production Monitoring

### 📊 Key Metrics to Monitor
- **Cluster Health**: Node status, pod status, resource utilization
- **Application Performance**: Dagster job success rates, execution times
- **Security Events**: Failed authentication attempts, unusual network traffic
- **Cost Optimization**: Spot instance usage, resource rightsizing

### 📈 CloudWatch Dashboards
- **EKS Cluster**: Node and pod metrics
- **Application**: Dagster-specific metrics
- **Cost**: Resource utilization and spending
- **Security**: VPC Flow Logs analysis

### 🚨 Recommended Alerts
- High CPU/memory utilization (>80%)
- Pod crash loops or failures
- Node failures or unavailability
- Unusual network traffic patterns
- Certificate expiration warnings

## 🛡️ Security Best Practices

### 🔐 Access Management
- Use IAM roles with least privilege principle
- Enable MFA for all admin access
- Regularly rotate access keys and certificates
- Monitor access logs and audit trails

### 🌐 Network Security
- Keep worker nodes in private subnets
- Use security groups with minimal required access
- Enable VPC Flow Logs for traffic analysis
- Regularly review and update CIDR ranges

### 🔑 Encryption
- Enable encryption at rest for all data
- Use KMS keys with automatic rotation
- Implement TLS for all communications
- Regularly update certificates

## 🔄 Maintenance & Updates

### 📅 Regular Maintenance Tasks

**Weekly:**
- Review CloudWatch logs and metrics
- Check for security alerts and patches
- Monitor cost and resource utilization

**Monthly:**
- Update EKS cluster version (if available)
- Review and update node group AMIs
- Audit IAM roles and permissions
- Test backup and recovery procedures

**Quarterly:**
- Review and update security groups
- Conduct disaster recovery tests
- Update Terraform modules to latest versions
- Review and optimize costs

### 🔄 Update Procedures

**EKS Cluster Updates:**
```bash
# Update cluster version
terraform plan -var cluster_version="1.32"
terraform apply -var cluster_version="1.32"

# Update node groups (rolling update)
terraform plan -target=module.eks.eks_managed_node_groups
terraform apply -target=module.eks.eks_managed_node_groups
```

**Addon Updates:**
```bash
# Update specific addons
terraform plan -target=module.eks_addons
terraform apply -target=module.eks_addons
```

## 🆘 Troubleshooting

### 🔧 Common Issues

**Issue: Cluster creation fails**
```bash
# Check AWS permissions
aws sts get-caller-identity
aws eks describe-cluster --name prod-eks-cluster

# Check VPC configuration
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=prod-vpc"
```

**Issue: Pods can't pull images**
```bash
# Check node group status
kubectl get nodes -o wide
kubectl describe node <node-name>

# Check IRSA configuration
kubectl get sa -n kube-system aws-load-balancer-controller -o yaml
```

**Issue: Load balancer not working**
```bash
# Check ALB controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check ingress resources
kubectl get ingress --all-namespaces
```

### 📞 Support Resources
- [AWS EKS Troubleshooting Guide](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [Terraform AWS Provider Issues](https://github.com/hashicorp/terraform-provider-aws/issues)

## 💰 Cost Optimization

### 💡 Cost-Saving Strategies
- **Spot Instances**: Use for non-critical workloads (configured in node groups)
- **Right-sizing**: Enable VPA for resource optimization recommendations
- **Karpenter**: Just-in-time provisioning reduces waste
- **Reserved Instances**: Consider for baseline capacity
- **Cleanup**: Regular cleanup of unused resources

### 📊 Cost Monitoring
- Enable AWS Cost Explorer
- Set up billing alerts
- Use Kubernetes resource quotas
- Monitor with AWS Cost and Usage Reports

## 🚀 Next Steps

### 🎯 Immediate Actions
1. **Configure monitoring alerts** for critical metrics
2. **Set up backup strategies** for persistent data
3. **Implement CI/CD pipeline** for application deployments
4. **Configure disaster recovery** procedures

### 📈 Future Enhancements
- **Service Mesh**: Implement Istio for advanced traffic management
- **GitOps**: Deploy ArgoCD for declarative application management
- **Multi-Region**: Extend to multiple regions for disaster recovery
- **Advanced Monitoring**: Implement Prometheus and Grafana stack

---

## 📞 Support & Documentation

For detailed information about individual modules and components, refer to:
- [VPC Module Documentation](../../modules/vpc/README.md)
- [EKS Module Documentation](../../modules/eks/README.md)
- [Security Module Documentation](../../modules/security/README.md)
- [EKS Addons Module Documentation](../../modules/eks-addons/README.md)

**Production Status**: ✅ **READY FOR DEPLOYMENT**

*Remember: This is production infrastructure. Always test changes in staging first and follow proper change management procedures.*
