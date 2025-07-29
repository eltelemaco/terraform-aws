# EKS Module using official terraform-aws-modules/eks
# Provides comprehensive EKS cluster management with managed node groups, Fargate, and auto mode support

module "eks" {
  source  = var.module_source
  version = var.module_version

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # VPC Configuration
  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # Cluster Configuration
  authentication_mode                      = var.authentication_mode
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  # Cluster Endpoint Configuration
  endpoint_public_access       = var.endpoint_public_access
  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  # Cluster Addons
  addons = var.addons

  # EKS Managed Node Groups
  eks_managed_node_groups = var.eks_managed_node_groups

  # Self Managed Node Groups
  self_managed_node_groups = var.self_managed_node_groups

  # Fargate Profiles
  fargate_profiles = var.fargate_profiles

  # Auto Mode Configuration
  compute_config = var.compute_config
  upgrade_policy = var.upgrade_policy

  # Cluster Security Group
  security_group_additional_rules = var.security_group_additional_rules

  # Node Security Group
  node_security_group_additional_rules = var.node_security_group_additional_rules

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = var.enable_irsa

  # OpenID Connect Provider
  openid_connect_audiences = var.openid_connect_audiences

  # Access Entries
  access_entries = var.access_entries

  # Identity Providers
  identity_providers = var.identity_providers

  # Encryption
  encryption_config = var.encryption_config

  # Logging
  enabled_log_types                      = var.enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.cloudwatch_log_group_kms_key_id
  create_cloudwatch_log_group            = var.create_cloudwatch_log_group

  # KMS
  create_kms_key                    = var.create_kms_key
  encryption_policy_use_name_prefix = var.encryption_policy_use_name_prefix
  kms_key_description               = var.kms_key_description
  kms_key_deletion_window_in_days   = var.kms_key_deletion_window_in_days
  enable_kms_key_rotation           = var.enable_kms_key_rotation

  # Timeouts
  timeouts = var.timeouts

  # Tags
  tags = merge(
    var.tags,
    {
      Terraform   = var.terraform_managed
      Environment = var.environment
      Module      = var.module_name
    }
  )

  cluster_tags = merge(
    var.cluster_tags,
    {
      Name = var.cluster_name
    }
  )
}

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for EKS cluster auth
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}
