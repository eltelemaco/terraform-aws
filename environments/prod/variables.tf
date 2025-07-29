# Production Environment Variables
# Production-optimized configuration with high availability and security

# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# VPC Configuration
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "prod-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.201.0/24", "10.2.202.0/24", "10.2.203.0/24"]
}

variable "elasticache_subnets" {
  description = "List of elasticache subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.221.0/24", "10.2.222.0/24", "10.2.223.0/24"]
}

variable "intra_subnets" {
  description = "List of intra subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.51.0/24", "10.2.52.0/24", "10.2.53.0/24"]
}

# NAT Gateway configuration - Production requires HA
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

# VPC Flow Logs - Required for production
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
  default     = "prod-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

# Cluster endpoint access - Production security
variable "endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false # Private-only for production
}

variable "endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = [] # No public access in production
}

# Authentication
variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API" # API-only for production
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry"
  type        = bool
  default     = true
}

# Addons - Full production addon suite
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
      configuration_values = jsonencode({
        replicaCount = 3
        resources = {
          limits = {
            cpu    = "100m"
            memory = "70Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "70Mi"
          }
        }
      })
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
          MINIMUM_IP_TARGET        = "20"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
    aws-efs-csi-driver = {
      most_recent = true
    }
    aws-load-balancer-controller = {
      most_recent = true
    }
    snapshot-controller = {
      most_recent = true
    }
    adot = {
      most_recent = true
    }
    aws-guardduty-agent = {
      most_recent = true
    }
  }
}

# EKS Managed Node Groups - Production-grade configurations
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
      max_unavailable_percentage = 25
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
    prod_general = {
      name = "prod-general-nodes"

      min_size     = 3
      max_size     = 20
      desired_size = 6

      instance_types = ["m5.xlarge", "m5.2xlarge"]
      capacity_type  = "ON_DEMAND"

      disk_size       = 200
      disk_type       = "gp3"
      disk_iops       = 3000
      disk_throughput = 125

      update_config = {
        max_unavailable_percentage = 25
      }

      labels = {
        Environment  = "prod"
        NodeGroup    = "general"
        WorkloadType = "general"
      }

      tags = {
        Environment = "prod"
        NodeGroup   = "general"
        Backup      = "daily"
      }
    }
    prod_compute = {
      name = "prod-compute-nodes"

      min_size     = 2
      max_size     = 10
      desired_size = 3

      instance_types = ["c5.2xlarge", "c5.4xlarge"]
      capacity_type  = "ON_DEMAND"

      disk_size       = 200
      disk_type       = "gp3"
      disk_iops       = 3000
      disk_throughput = 125

      update_config = {
        max_unavailable_percentage = 25
      }

      labels = {
        Environment  = "prod"
        NodeGroup    = "compute"
        WorkloadType = "compute-intensive"
      }

      taints = [{
        key    = "workload-type"
        value  = "compute"
        effect = "NO_SCHEDULE"
      }]

      tags = {
        Environment = "prod"
        NodeGroup   = "compute"
        Backup      = "daily"
      }
    }
    prod_memory = {
      name = "prod-memory-nodes"

      min_size     = 1
      max_size     = 5
      desired_size = 2

      instance_types = ["r5.xlarge", "r5.2xlarge"]
      capacity_type  = "ON_DEMAND"

      disk_size       = 200
      disk_type       = "gp3"
      disk_iops       = 3000
      disk_throughput = 125

      update_config = {
        max_unavailable_percentage = 25
      }

      labels = {
        Environment  = "prod"
        NodeGroup    = "memory"
        WorkloadType = "memory-intensive"
      }

      taints = [{
        key    = "workload-type"
        value  = "memory"
        effect = "NO_SCHEDULE"
      }]

      tags = {
        Environment = "prod"
        NodeGroup   = "memory"
        Backup      = "daily"
      }
    }
  }
}

# Logging - Full logging for production
variable "enabled_log_types" {
  description = "List of log types to enable for EKS cluster"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 90
}

# KMS - Required for production
variable "create_kms_key" {
  description = "Controls if a KMS key for cluster encryption should be created"
  type        = bool
  default     = true
}

variable "enable_kms_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = true
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
    Environment = "prod"
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
