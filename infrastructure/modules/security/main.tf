# Security Module for EKS Infrastructure
# Provides comprehensive security group management, IAM policies, and security configurations
# Leverages terraform-aws-modules/security-group for best practices

# EKS Cluster Security Group
module "eks_cluster_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${var.cluster_name}-cluster-additional-sg"
  description = "Additional security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # EKS API Server Access
  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS access to EKS API server"
      cidr_blocks = join(",", var.api_server_access_cidrs)
    }
  ]

  # Node to control plane communication
  ingress_with_source_security_group_id = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "Node to control plane API server"
      source_security_group_id = module.eks_node_security_group.security_group_id
    }
  ]

  # All outbound traffic
  egress_rules = ["all-all"]

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-cluster-additional-sg"
      Type        = "eks-cluster"
      Environment = var.environment
      Module      = "security"
    }
  )
}

# EKS Node Security Group
module "eks_node_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${var.cluster_name}-node-additional-sg"
  description = "Additional security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Node to node communication
  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]

  # Control plane to node communication
  ingress_with_source_security_group_id = [
    {
      from_port                = 1025
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Control plane to node kubelet"
      source_security_group_id = module.eks_cluster_security_group.security_group_id
    },
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "Control plane to node webhook"
      source_security_group_id = module.eks_cluster_security_group.security_group_id
    }
  ]

  # CoreDNS
  ingress_with_cidr_blocks = [
    {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      description = "CoreDNS TCP"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      description = "CoreDNS UDP"
      cidr_blocks = var.vpc_cidr
    }
  ]

  # All outbound traffic
  egress_rules = ["all-all"]

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-node-additional-sg"
      Type        = "eks-node"
      Environment = var.environment
      Module      = "security"
    }
  )
}

# Load Balancer Security Group (for ALB/NLB ingress)
module "load_balancer_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  count = var.create_load_balancer_sg ? 1 : 0

  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # HTTP and HTTPS ingress
  ingress_rules = ["http-80-tcp", "https-443-tcp"]

  # Custom ingress rules for additional ports
  ingress_with_cidr_blocks = var.additional_ingress_rules

  # All outbound traffic
  egress_rules = ["all-all"]

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-alb-sg"
      Type        = "load-balancer"
      Environment = var.environment
      Module      = "security"
    }
  )
}

# Database Security Group (for RDS if needed)
module "database_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  count = var.create_database_sg ? 1 : 0

  name        = "${var.cluster_name}-db-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  # Database access from nodes
  ingress_with_source_security_group_id = [
    {
      from_port                = var.database_port
      to_port                  = var.database_port
      protocol                 = "tcp"
      description              = "Database access from EKS nodes"
      source_security_group_id = module.eks_node_security_group.security_group_id
    }
  ]

  # Additional database access
  ingress_with_cidr_blocks = var.database_access_cidrs

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-db-sg"
      Type        = "database"
      Environment = var.environment
      Module      = "security"
    }
  )
}

# EFS Security Group (for persistent storage)
module "efs_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  count = var.create_efs_sg ? 1 : 0

  name        = "${var.cluster_name}-efs-sg"
  description = "Security group for EFS file system"
  vpc_id      = var.vpc_id

  # NFS access from nodes
  ingress_with_source_security_group_id = [
    {
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      description              = "NFS access from EKS nodes"
      source_security_group_id = module.eks_node_security_group.security_group_id
    }
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-efs-sg"
      Type        = "efs"
      Environment = var.environment
      Module      = "security"
    }
  )
}

# KMS Key for EKS encryption
resource "aws_kms_key" "eks" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for EKS cluster ${var.cluster_name} encryption"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation # Enabled key rotation

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-eks-kms-key"
      Environment = var.environment
      Module      = "security"
    }
  )
}

# KMS Key Alias
resource "aws_kms_alias" "eks" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${var.cluster_name}-eks-key"
  target_key_id = aws_kms_key.eks[0].key_id
}

# KMS Key Policy
resource "aws_kms_key_policy" "eks" {
  count = var.create_kms_key ? 1 : 0

  key_id = aws_kms_key.eks[0].id
  policy = data.aws_iam_policy_document.kms_key_policy[0].json
}

# KMS Key Policy Document
data "aws_iam_policy_document" "kms_key_policy" {
  count = var.create_kms_key ? 1 : 0

  # Default key policy
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # EKS cluster access
  statement {
    sid    = "EnableEKSAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }

  # Additional administrators
  dynamic "statement" {
    for_each = length(var.kms_key_administrators) > 0 ? [1] : []

    content {
      sid    = "EnableAdministratorAccess"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.kms_key_administrators
      }

      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ]

      resources = ["*"]
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Network ACL for additional subnet protection
resource "aws_network_acl" "eks_private" {
  count = var.create_network_acl ? 1 : 0

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Allow inbound traffic within VPC
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  # Allow inbound HTTPS from allowed CIDRs
  dynamic "ingress" {
    for_each = var.api_server_access_cidrs

    content {
      protocol   = "tcp"
      rule_no    = 200 + ingress.key
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 443
      to_port    = 443
    }
  }

  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-private-nacl"
      Environment = var.environment
      Module      = "security"
    }
  )
}

# WAF Web ACL for ALB protection (optional)
resource "aws_wafv2_web_acl" "eks_alb" {
  count = var.create_waf_acl ? 1 : 0

  name  = "${var.cluster_name}-alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting rule
  dynamic "rule" {
    for_each = var.waf_rate_limit > 0 ? [1] : []

    content {
      name     = "RateLimitRule"
      priority = 3

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.waf_rate_limit
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimitRuleMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-alb-waf"
      Environment = var.environment
      Module      = "security"
    }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.cluster_name}ALBWebACL"
    sampled_requests_enabled   = true
  }
}

# GuardDuty Detector (optional)
resource "aws_guardduty_detector" "eks" {
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = var.guardduty_finding_frequency

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-guardduty"
      Environment = var.environment
      Module      = "security"
    }
  )
}
