# Security Module Variables
# Configuration inputs for the security module providing comprehensive AWS security configurations

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for network ACL"
  type        = list(string)
  default     = []
}

# API Server Access
variable "api_server_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS API server"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# Security Group Controls
variable "create_load_balancer_sg" {
  description = "Whether to create security group for load balancers"
  type        = bool
  default     = true
}

variable "create_database_sg" {
  description = "Whether to create security group for databases"
  type        = bool
  default     = false
}

variable "create_efs_sg" {
  description = "Whether to create security group for EFS"
  type        = bool
  default     = false
}

# Additional Ingress Rules for Load Balancer
variable "additional_ingress_rules" {
  description = "Additional ingress rules for load balancer security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
    cidr_blocks = string
  }))
  default = []
}

# Database Configuration
variable "database_port" {
  description = "Port for database access"
  type        = number
  default     = 5432
}

variable "database_access_cidrs" {
  description = "CIDR blocks for additional database access"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
    cidr_blocks = string
  }))
  default = []
}

# KMS Configuration
variable "create_kms_key" {
  description = "Whether to create KMS key for EKS encryption"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window_in_days" {
  description = "The waiting period, specified in number of days, before the KMS key is deleted"
  type        = number
  default     = 7
}

variable "enable_kms_key_rotation" {
  description = "Specifies whether key rotation is enabled for the KMS key"
  type        = bool
  default     = true
}

variable "kms_key_administrators" {
  description = "List of IAM ARNs for key administrators"
  type        = list(string)
  default     = []
}

# Network ACL
variable "create_network_acl" {
  description = "Whether to create network ACL for additional subnet protection"
  type        = bool
  default     = false
}

# WAF Configuration
variable "create_waf_acl" {
  description = "Whether to create WAF Web ACL for ALB protection"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF (requests per 5 minutes per IP). Set to 0 to disable rate limiting"
  type        = number
  default     = 2000
}

# GuardDuty Configuration
variable "enable_guardduty" {
  description = "Whether to enable GuardDuty for threat detection"
  type        = bool
  default     = false
}

variable "guardduty_finding_frequency" {
  description = "Specifies the frequency of notifications sent for subsequent finding occurrences"
  type        = string
  default     = "SIX_HOURS"
  validation {
    condition = contains([
      "FIFTEEN_MINUTES",
      "ONE_HOUR",
      "SIX_HOURS"
    ], var.guardduty_finding_frequency)
    error_message = "GuardDuty finding frequency must be one of: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}

# Compliance and Security Features
variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs for security monitoring"
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination. Valid values: cloud-watch-logs, s3"
  type        = string
  default     = "cloud-watch-logs"
  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "Flow log destination type must be either 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_log_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in CloudWatch Logs"
  type        = number
  default     = 14
}

# Security Policies Configuration
variable "enforce_imdsv2" {
  description = "Whether to enforce IMDSv2 for EC2 instances"
  type        = bool
  default     = true
}

variable "block_device_encrypted" {
  description = "Whether to encrypt EBS block devices by default"
  type        = bool
  default     = true
}

# Monitoring and Alerting
variable "enable_security_monitoring" {
  description = "Whether to enable comprehensive security monitoring"
  type        = bool
  default     = true
}

variable "security_notification_email" {
  description = "Email address for security notifications"
  type        = string
  default     = null
}

# Network Security
variable "enable_network_isolation" {
  description = "Whether to enable strict network isolation policies"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access (if any)"
  type        = list(string)
  default     = []
}

# Container Security
variable "enable_pod_security_policy" {
  description = "Whether to enable Kubernetes Pod Security Policies"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Whether to enable Kubernetes Network Policies"
  type        = bool
  default     = true
}

# Secrets Management
variable "secrets_manager_kms_key_id" {
  description = "KMS key ID for AWS Secrets Manager encryption"
  type        = string
  default     = null
}

variable "enable_secrets_rotation" {
  description = "Whether to enable automatic secrets rotation"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "security_group_tags" {
  description = "Additional tags for security groups"
  type        = map(string)
  default     = {}
}
