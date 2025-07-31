# Production Environment Outputs
# Critical infrastructure outputs for production environment

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = module.vpc.elasticache_subnets
}

output "intra_subnets" {
  description = "List of IDs of intra subnets"
  value       = module.vpc.intra_subnets
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.natgw_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

# Security Outputs
output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = module.security.cluster_security_group_id
}

output "worker_security_group_id" {
  description = "ID of the worker security group"
  value       = module.security.worker_security_group_id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = module.security.database_security_group_id
}

# EKS Cluster Outputs
output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = module.eks.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.eks.cluster_status
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_auth_token" {
  description = "Authentication token for the EKS cluster"
  value       = module.eks.cluster_auth_token
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider if enabled"
  value       = module.eks.oidc_provider_arn
}

# EKS Node Groups
output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = module.eks.eks_managed_node_groups
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by EKS managed node groups"
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
}

# Cluster Add-ons
output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = module.eks.cluster_addons
}

output "cluster_identity_providers" {
  description = "Map of attribute maps for all EKS identity providers enabled"
  value       = module.eks.cluster_identity_providers
}

# KMS Key
output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt EKS cluster"
  value       = module.eks.kms_key_arn
}

output "kms_key_id" {
  description = "ID of the KMS key used to encrypt EKS cluster"
  value       = module.eks.kms_key_id
}

# CloudWatch Log Group
output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group created"
  value       = module.eks.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of cloudwatch log group created"
  value       = module.eks.cloudwatch_log_group_arn
}

# EKS Addons Outputs
output "eks_addons_status" {
  description = "Status of EKS managed addons"
  value       = module.eks_addons.addons_status
}

# ALB Controller
output "alb_controller_status" {
  description = "AWS Load Balancer Controller deployment status"
  value       = module.alb_controller.controller_status
}

# Dagster Outputs
output "dagster_namespace" {
  description = "Kubernetes namespace where Dagster is deployed"
  value       = module.dagster.namespace
}

output "dagster_release_name" {
  description = "Helm release name for Dagster"
  value       = module.dagster.release_name
}

output "dagster_web_url" {
  description = "URL to access Dagster webserver"
  value       = module.dagster.webserver_url
}

# kubectl command
output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

# Production readiness indicators
output "production_readiness_checklist" {
  description = "Production environment readiness indicators"
  value = {
    high_availability = {
      multi_az_subnets        = length(var.private_subnets) >= 3
      multi_az_nat_gateway    = var.one_nat_gateway_per_az
      multi_node_groups       = length(var.eks_managed_node_groups) > 1
      cluster_endpoint_config = var.endpoint_private_access && length(var.endpoint_public_access_cidrs) > 0
    }
    security = {
      private_endpoint_enabled = var.endpoint_private_access
      kms_encryption_enabled   = var.create_kms_key
      flow_logs_enabled        = var.enable_flow_log
      comprehensive_logging    = length(var.enabled_log_types) >= 4
      vpc_flow_logs            = var.enable_flow_log
    }
    scalability = {
      cluster_autoscaler_ready = true
      karpenter_enabled        = true
      multiple_instance_types  = true
      spot_instances_available = contains([for ng in var.eks_managed_node_groups : ng.capacity_type], "SPOT")
    }
    observability = {
      cloudwatch_retention_days    = var.cloudwatch_log_group_retention_in_days
      aws_load_balancer_controller = true
      metrics_server_enabled       = true
      external_secrets_enabled     = true
      cert_manager_enabled         = true
    }
    compliance = {
      encryption_at_rest = var.create_kms_key
      backup_strategy    = "RDS automated backups + EBS snapshots"
      disaster_recovery  = "Multi-AZ deployment"
      monitoring_alerts  = "CloudWatch + Prometheus"
    }
  }
}

# Critical infrastructure summary
output "production_infrastructure_summary" {
  description = "Summary of production infrastructure components"
  value = {
    environment        = "production"
    cluster_name       = module.eks.cluster_name
    cluster_version    = module.eks.cluster_version
    vpc_cidr           = module.vpc.vpc_cidr_block
    availability_zones = length(var.private_subnets)
    node_groups        = length(var.eks_managed_node_groups)
    addons_enabled = [
      "AWS Load Balancer Controller",
      "Metrics Server",
      "Cluster Autoscaler",
      "Karpenter",
      "cert-manager",
      "External Secrets",
      "VPA",
      "EFS CSI Driver",
      "External DNS",
      "FluentBit"
    ]
    applications = [
      "Dagster Data Platform"
    ]
    security_features = [
      "KMS encryption",
      "VPC Flow Logs",
      "Private subnets",
      "Security groups",
      "IRSA",
      "RBAC"
    ]
  }
}
