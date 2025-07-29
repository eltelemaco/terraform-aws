# Development Environment Main Configuration
# This file orchestrates the infrastructure deployment for the development environment

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
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_name           = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  environment        = var.environment
  availability_zones = data.aws_availability_zones.available.names

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

# EKS Module
module "eks" {
  source = "../../modules/eks"

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

  depends_on = [module.vpc]
}

# Configure Kubernetes and Helm providers
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
