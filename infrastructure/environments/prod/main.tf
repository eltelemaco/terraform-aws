# Production Environment - Enterprise-Grade Infrastructure
# High availability, security, and performance optimized for production workloads
# Follows best practices for mission-critical environments

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.14"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }

  # Remote state backend for production (CRITICAL: Configure before deployment)
  # backend "s3" {
  #   bucket         = "terraform-state-prod-secure"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-west-2"
  #   encrypt        = true
  #   kms_key_id     = "arn:aws:kms:us-west-2:ACCOUNT:key/KEY-ID"
  #   dynamodb_table = "terraform-state-lock-prod"
  # }
}

# Configure the AWS Provider with enhanced security
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment  = "prod"
      Project      = "terraform-aws"
      ManagedBy    = "Terraform"
      CostCenter   = "infrastructure"
      Backup       = "daily"
      Compliance   = "required"
      DataClass    = "confidential"
      BusinessUnit = "platform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module - Production Network Architecture
module "vpc" {
  # Using official terraform-aws-modules/vpc as recommended by MCP guidance
  source = "../../modules/vpc"

  vpc_name           = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  environment        = var.environment
  availability_zones = data.aws_availability_zones.available.names

  # Multi-AZ subnet configuration for high availability
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets
  database_subnets    = var.database_subnets
  elasticache_subnets = var.elasticache_subnets
  intra_subnets       = var.intra_subnets

  # Production NAT Gateway configuration - Multi-AZ for redundancy
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # DNS configuration
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # Enhanced VPC Flow Logs for production security monitoring
  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_log_group = var.create_flow_log_cloudwatch_log_group
  create_flow_log_cloudwatch_iam_role  = var.create_flow_log_cloudwatch_iam_role

  tags = var.tags
}

# Security Module - Enhanced security controls for production
module "security" {
  source = "../../modules/security"

  cluster_name = var.cluster_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr_block

  # Subnet configuration
  private_subnet_ids = module.vpc.private_subnets

  # Strict API server access for production
  api_server_access_cidrs = var.endpoint_public_access_cidrs

  # Enhanced security controls for production
  create_load_balancer_sg = true
  create_database_sg      = true
  create_efs_sg           = true

  tags = var.tags

  depends_on = [module.vpc]
}

# EKS Module - Production-grade Kubernetes cluster
module "eks" {
  # Using official terraform-aws-modules/eks as discovered via MCP search
  source = var.eks_module_source

  # Module configuration
  module_source     = "terraform-aws-modules/eks/aws"
  module_version    = var.eks_module_version
  module_name       = var.eks_module_name
  terraform_managed = var.eks_terraform_managed

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  environment     = var.environment

  # VPC Configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  # Production cluster endpoint access - Private by default with limited public access
  endpoint_public_access       = var.endpoint_public_access
  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  # Enhanced authentication for production
  authentication_mode                      = var.authentication_mode
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  # Production cluster addons
  addons = var.addons

  # Production-optimized EKS Managed Node Groups
  eks_managed_node_groups = var.eks_managed_node_groups

  # Comprehensive logging for production
  enabled_log_types                      = var.enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  # Enhanced encryption for production
  create_kms_key          = var.create_kms_key
  enable_kms_key_rotation = var.enable_kms_key_rotation

  # IRSA for AWS services integration
  enable_irsa = var.enable_irsa

  # Access entries for production RBAC
  access_entries = var.access_entries

  tags         = var.tags
  cluster_tags = var.cluster_tags

  depends_on = [module.vpc, module.security]
}

# EKS Addons Module - Enterprise-grade cluster addons using AWS-IA blueprints
module "eks_addons" {
  source = "../../modules/eks-addons"

  # Cluster configuration
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn
  aws_region        = var.aws_region

  # Core EKS addons - enabled by default for production
  enable_core_addons = true

  # AWS Load Balancer Controller for production
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller_config = {
    chart_version = "1.8.1"
    replicas      = 3
    log_level     = "info"
  }

  # Metrics Server for HPA
  enable_metrics_server = true
  metrics_server_config = {
    chart_version = "3.12.1"
    replicas      = 3
  }

  # Cluster Autoscaler for production scaling
  enable_cluster_autoscaler = true
  cluster_autoscaler_config = {
    chart_version = "9.37.0"
    replicas      = 3
  }

  # Karpenter for advanced node provisioning
  enable_karpenter = true
  karpenter_config = {
    chart_version = "1.0.2"
    replicas      = 3
  }

  # cert-manager for TLS certificate management
  enable_cert_manager = true
  cert_manager_config = {
    chart_version = "v1.15.1"
    replicas      = 3
  }

  # External Secrets Operator for secret management
  enable_external_secrets = true
  external_secrets_config = {
    chart_version = "0.9.20"
    replicas      = 3
  }

  # Vertical Pod Autoscaler for resource optimization
  enable_vpa = true

  # EFS CSI Driver
  enable_aws_efs_csi_driver = true

  # External DNS
  enable_external_dns = true

  # AWS for FluentBit for logging
  enable_aws_for_fluentbit = true

  depends_on = [module.eks]
}

# Configure Kubernetes and Helm providers after EKS cluster creation
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = module.eks.cluster_auth_token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = module.eks.cluster_auth_token
  }
}

# AWS Load Balancer Controller for production ingress
module "alb_controller" {
  source = "../../../app/aws_load_balancer_controller"

  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
  vpc_id       = module.vpc.vpc_id

  # Production namespace
  namespace        = "kube-system"
  create_namespace = false

  # Latest stable version
  chart_version = "1.8.1"

  # Production configuration - 3 replicas for HA
  replicas = 3

  # Enhanced resource limits for production
  cpu_request    = "200m"
  cpu_limit      = "500m"
  memory_request = "500Mi"
  memory_limit   = "1Gi"

  tags = var.tags

  # Ensure EKS cluster and addons are ready
  depends_on = [
    module.eks,
    module.eks_addons
  ]
}

# Random password for Dagster PostgreSQL
resource "random_password" "dagster_db" {
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Dagster Data Orchestration Platform for production
module "dagster" {
  source = "../../../app/dagster"

  # Cluster configuration
  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
  vpc_id       = module.vpc.vpc_id

  # Production namespace
  namespace = var.dagster_namespace

  # Helm chart configuration
  chart_version = var.dagster_chart_version

  # IRSA configuration for AWS services integration
  enable_irsa       = var.dagster_enable_irsa
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_host  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  # Production database configuration with RDS
  postgresql_enabled  = var.dagster_postgresql_enabled
  postgresql_password = var.dagster_postgresql_password != "" ? var.dagster_postgresql_password : "dagster-prod-${random_password.dagster_db.result}"

  # Storage configuration
  s3_bucket_name         = var.dagster_s3_bucket_name
  enable_s3_compute_logs = var.enable_dagster_s3_logs

  # Production scaling configuration
  replicas = var.dagster_replicas

  # Enhanced resource configuration for production
  webserver_resources = var.dagster_webserver_resources
  daemon_resources    = var.dagster_daemon_resources

  # Run launcher configuration
  run_launcher_type = var.dagster_run_launcher_type

  # Production ingress configuration
  ingress_enabled = var.dagster_ingress_enabled
  ingress_host    = var.dagster_ingress_host
  ingress_class   = var.dagster_ingress_class

  # Monitoring and observability
  enable_prometheus_monitoring = var.dagster_enable_prometheus_monitoring
  enable_debug_mode            = false # Disabled for production

  tags = merge(var.tags, var.dagster_additional_tags)

  # Ensure all infrastructure is ready
  depends_on = [
    module.eks,
    module.eks_addons,
    module.alb_controller,
    module.security
  ]
}
