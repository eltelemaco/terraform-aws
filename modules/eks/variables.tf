# EKS Module Variables
# Configuration inputs for the EKS module using terraform-aws-modules/eks

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# VPC Configuration
variable "vpc_id" {
  description = "ID of the VPC where the cluster will be provisioned"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the nodes/node groups will be provisioned"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned"
  type        = list(string)
  default     = []
}

# Cluster Configuration
variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator as an administrator via access entry"
  type        = bool
  default     = false
}

# Cluster Endpoint Configuration
variable "endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Cluster Addons
variable "addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type = map(object({
    name                        = optional(string)
    before_compute              = optional(bool, false)
    most_recent                 = optional(bool, true)
    addon_version               = optional(string)
    configuration_values        = optional(string)
    preserve                    = optional(bool, true)
    resolve_conflicts_on_create = optional(string, "NONE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn    = optional(string)
    tags                        = optional(map(string), {})
  }))
  default = {}
}

# EKS Managed Node Groups
variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

# Self Managed Node Groups
variable "self_managed_node_groups" {
  description = "Map of self-managed node group definitions to create"
  type        = any
  default     = {}
}

# Fargate Profiles
variable "fargate_profiles" {
  description = "Map of Fargate Profile definitions to create"
  type        = any
  default     = {}
}

# Auto Mode Configuration
variable "compute_config" {
  description = "Configuration block for the cluster compute configuration"
  type = object({
    enabled       = optional(bool, false)
    node_pools    = optional(list(string))
    node_role_arn = optional(string)
  })
  default = null
}

variable "upgrade_policy" {
  description = "Configuration block for the cluster upgrade policy"
  type = object({
    support_type = optional(string)
  })
  default = null
}

# Security Groups
variable "security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group created"
  type = map(object({
    protocol                   = optional(string, "tcp")
    from_port                  = number
    to_port                    = number
    type                       = optional(string, "ingress")
    description                = optional(string)
    cidr_blocks                = optional(list(string))
    ipv6_cidr_blocks           = optional(list(string))
    prefix_list_ids            = optional(list(string))
    self                       = optional(bool)
    source_node_security_group = optional(bool, false)
    source_security_group_id   = optional(string)
  }))
  default = {}
}

variable "node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created"
  type = map(object({
    protocol                      = optional(string, "tcp")
    from_port                     = number
    to_port                       = number
    type                          = optional(string, "ingress")
    description                   = optional(string)
    cidr_blocks                   = optional(list(string))
    ipv6_cidr_blocks              = optional(list(string))
    prefix_list_ids               = optional(list(string))
    self                          = optional(bool)
    source_cluster_security_group = optional(bool, false)
    source_security_group_id      = optional(string)
  }))
  default = {}
}

# IRSA
variable "enable_irsa" {
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "openid_connect_audiences" {
  description = "List of OpenID Connect audience client IDs to add to the IRSA provider"
  type        = list(string)
  default     = []
}

# Access Entries
variable "access_entries" {
  description = "Map of access entries to add to the cluster"
  type = map(object({
    kubernetes_groups = optional(list(string))
    principal_arn     = string
    type              = optional(string, "STANDARD")
    user_name         = optional(string)
    tags              = optional(map(string), {})
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        namespaces = optional(list(string))
        type       = string
      })
    })))
  }))
  default = {}
}

# Identity Providers
variable "identity_providers" {
  description = "Map of cluster identity provider configurations to enable for the cluster"
  type = map(object({
    client_id                     = string
    groups_claim                  = optional(string)
    groups_prefix                 = optional(string)
    identity_provider_config_name = optional(string)
    issuer_url                    = string
    required_claims               = optional(map(string))
    username_claim                = optional(string)
    username_prefix               = optional(string)
    tags                          = optional(map(string), {})
  }))
  default = {}
}

# Encryption
variable "encryption_config" {
  description = "Configuration block with encryption configuration for the cluster"
  type = object({
    provider_key_arn = optional(string)
    resources        = optional(list(string), ["secrets"])
  })
  default = {}
}

# Logging
variable "enabled_log_types" {
  description = "A list of the desired control plane logs to enable"
  type        = list(string)
  default     = ["audit", "api", "authenticator"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 90
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group"
  type        = string
  default     = null
}

variable "create_cloudwatch_log_group" {
  description = "Determines whether a log group is created by this module for the cluster logs"
  type        = bool
  default     = true
}

# KMS
variable "create_kms_key" {
  description = "Controls if a KMS key for cluster encryption should be created"
  type        = bool
  default     = true
}

variable "encryption_policy_use_name_prefix" {
  description = "Determines whether cluster encryption policy name is used as a prefix"
  type        = bool
  default     = true
}

variable "kms_key_description" {
  description = "The description of the key as viewed in AWS console"
  type        = string
  default     = null
}

variable "kms_key_deletion_window_in_days" {
  description = "The waiting period, specified in number of days"
  type        = number
  default     = null
}

variable "enable_kms_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = true
}

# Timeouts
variable "timeouts" {
  description = "Create, update, and delete timeout configurations for the cluster"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "A map of additional tags to add to the cluster"
  type        = map(string)
  default     = {}
}
