# Development Environment Variables

# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# VPC Configuration
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "dev-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
}

variable "elasticache_subnets" {
  description = "List of elasticache subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.221.0/24", "10.0.222.0/24", "10.0.223.0/24"]
}

variable "intra_subnets" {
  description = "List of intra subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.51.0/24", "10.0.52.0/24", "10.0.53.0/24"]
}

# NAT Gateway configuration
variable "enable_nat_gateway" {
  description = "Should be true to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true to provision NAT Gateways in each AZ"
  type        = bool
  default     = true
}

# DNS configuration
variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

# VPC Flow Logs
variable "enable_flow_log" {
  description = "Whether or not to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "create_flow_log_cloudwatch_log_group" {
  description = "Whether to create CloudWatch log group for VPC Flow Logs"
  type        = bool
  default     = true
}

variable "create_flow_log_cloudwatch_iam_role" {
  description = "Whether to create IAM role for VPC Flow Logs"
  type        = bool
  default     = true
}

# EKS Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "dev-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

# Cluster endpoint access
variable "endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Authentication
variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry"
  type        = bool
  default     = true
}

# Addons
variable "addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type = map(object({
    most_recent                 = optional(bool, true)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "PRESERVE")
    preserve                    = optional(bool, true)
    configuration_values        = optional(string)
    tags                        = optional(map(string), {})
  }))
  default = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
}

# EKS Managed Node Groups
variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions"
  type = map(object({
    name            = optional(string)
    use_name_prefix = optional(bool, true)

    subnet_ids = optional(list(string))

    min_size     = optional(number, 1)
    max_size     = optional(number, 10)
    desired_size = optional(number, 2)

    ami_id         = optional(string)
    ami_type       = optional(string, "AL2_x86_64")
    platform       = optional(string, "linux")
    capacity_type  = optional(string, "ON_DEMAND")
    instance_types = optional(list(string), ["t3.medium"])

    disk_size       = optional(number, 50)
    disk_type       = optional(string, "gp3")
    disk_iops       = optional(number)
    disk_throughput = optional(number)

    update_config = optional(map(string), {
      max_unavailable_percentage = 50
    })

    remote_access = optional(map(string), {})

    labels = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])

    tags = optional(map(string), {})
  }))
  default = {
    dev_nodes = {
      name = "dev-node-group"

      min_size     = 1
      max_size     = 5
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      disk_size = 50
      disk_type = "gp3"

      labels = {
        Environment = "dev"
        NodeGroup   = "dev-nodes"
      }

      tags = {
        Environment = "dev"
        NodeGroup   = "dev-nodes"
      }
    }
  }
}

# Logging
variable "enabled_log_types" {
  description = "List of log types to enable for EKS cluster"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 7
}

# KMS
variable "create_kms_key" {
  description = "Controls if a KMS key for cluster encryption should be created"
  type        = bool
  default     = false
}

variable "enable_kms_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = false
}

# IRSA
variable "enable_irsa" {
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

# Access entries
variable "access_entries" {
  description = "Map of access entries to add to the cluster"
  type = map(object({
    kubernetes_groups = optional(list(string), [])
    principal_arn     = string
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        namespaces = optional(list(string))
        type       = string
      })
    })), {})
    type      = string
    user_name = optional(string)
  }))
  default = {}
}

# Common tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "terraform-aws"
  }
}

variable "cluster_tags" {
  description = "A map of additional tags to add to the cluster"
  type        = map(string)
  default = {
    GithubRepo = "terraform-aws"
    GithubOrg  = "terraform-aws"
  }
}
