# Development Environment - Infrastructure Orchestration
# Deploys and configures the complete development infrastructure stack

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

  # Remote state backend (configure as needed)
  # backend "s3" {
  #   bucket         = "terraform-state-dev"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-west-2"
  #   encrypt        = true
  #   use_lockfile   = true
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "terraform-aws"
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "this" {
  state = "available"
}

data "aws_caller_identity" "this" {}

# VPC Module
module "vpc" {
  # Module discovered and documented using Terraform MCP for compliance and best practices
  source = "../../modules/vpc"

  vpc_name           = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  environment        = var.environment
  availability_zones = data.aws_availability_zones.this.names

  # Subnets
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets
  database_subnets    = var.database_subnets
  elasticache_subnets = var.elasticache_subnets
  intra_subnets       = var.intra_subnets

  # NAT Gateway configuration
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # DNS and other VPC settings
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # VPC Flow Logs
  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_log_group = var.create_flow_log_cloudwatch_log_group
  create_flow_log_cloudwatch_iam_role  = var.create_flow_log_cloudwatch_iam_role

  tags = var.tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  cluster_name = var.cluster_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr_block

  # Subnet configuration
  private_subnet_ids = module.vpc.private_subnets

  # API server access configuration
  api_server_access_cidrs = var.endpoint_public_access_cidrs

  # Security group controls for development
  create_load_balancer_sg = true
  create_database_sg      = false
  create_efs_sg           = false

  tags = var.tags

  depends_on = [module.vpc]
}

# EKS Module
module "eks" {
  # Module discovered and documented using Terraform MCP for compliance and best practices
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

  # Cluster endpoint access
  endpoint_public_access       = var.endpoint_public_access
  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  # Authentication
  authentication_mode                      = var.authentication_mode
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  # Cluster addons
  addons = var.addons

  # EKS Managed Node Groups
  eks_managed_node_groups = var.eks_managed_node_groups

  # Logging
  enabled_log_types                      = var.enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  # KMS encryption
  create_kms_key          = var.create_kms_key
  enable_kms_key_rotation = var.enable_kms_key_rotation

  # IRSA
  enable_irsa = var.enable_irsa

  # Access entries
  access_entries = var.access_entries

  tags         = var.tags
  cluster_tags = var.cluster_tags

  depends_on = [module.vpc, module.security]
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

# AWS Load Balancer Controller
module "alb_controller" {
  source = "../../../app/aws_load_balancer_controller"

  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
  vpc_id       = module.vpc.vpc_id

  # Use default namespace (kube-system)
  namespace        = "kube-system"
  create_namespace = false

  # Use latest stable version
  chart_version = "1.8.1"

  # Development configuration - 2 replicas for HA
  replicas = 2

  # Resource limits for development
  cpu_request    = "100m"
  cpu_limit      = "200m"
  memory_request = "200Mi"
  memory_limit   = "500Mi"

  tags = var.tags

  # Ensure EKS cluster and node groups are ready
  depends_on = [
    module.eks,
    module.eks.eks_managed_node_groups
  ]
}

# Random password for Dagster PostgreSQL (if not provided)
resource "random_password" "dagster_db" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Dagster Data Orchestration Platform
module "dagster" {
  source = "../../../app/dagster"

  # Cluster configuration
  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
  vpc_id       = module.vpc.vpc_id

  # Namespace configuration
  namespace = var.dagster_namespace

  # Helm chart configuration
  chart_version = var.dagster_chart_version

  # IRSA configuration for AWS services integration
  enable_irsa       = var.dagster_enable_irsa
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_host  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  # Database configuration
  postgresql_enabled  = var.dagster_postgresql_enabled
  postgresql_password = var.dagster_postgresql_password != "" ? var.dagster_postgresql_password : "dagster-dev-${random_password.dagster_db.result}"

  # Storage configuration
  s3_bucket_name         = var.dagster_s3_bucket_name
  enable_s3_compute_logs = var.enable_dagster_s3_logs

  # Scaling configuration
  replicas = var.dagster_replicas

  # Resource configuration
  webserver_resources = var.dagster_webserver_resources
  daemon_resources    = var.dagster_daemon_resources

  # Run launcher configuration
  run_launcher_type = var.dagster_run_launcher_type

  # Ingress configuration
  ingress_enabled = var.dagster_ingress_enabled
  ingress_host    = var.dagster_ingress_host
  ingress_class   = var.dagster_ingress_class

  # Monitoring and debug configuration
  enable_prometheus_monitoring = var.dagster_enable_prometheus_monitoring
  enable_debug_mode            = var.dagster_enable_debug_mode

  tags = merge(var.tags, var.dagster_additional_tags)

  # Ensure all infrastructure is ready
  depends_on = [
    module.eks,
    module.alb_controller,
    module.security
  ]
}
