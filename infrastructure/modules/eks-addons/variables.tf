# EKS Blueprints Addons Module Variables
# Configures enterprise-grade EKS addons for production workloads

# Cluster Information
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes cluster version"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the cluster OIDC Provider"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# Core EKS Add-ons
variable "enable_core_addons" {
  description = "Enable core EKS add-ons (EBS CSI, CoreDNS, VPC CNI, Kube-proxy)"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_version" {
  description = "Version of the EBS CSI driver addon"
  type        = string
  default     = "v1.35.0-eksbuild.1"
}

variable "ebs_csi_service_account_role_arn" {
  description = "IAM role ARN for EBS CSI driver service account"
  type        = string
  default     = null
}

variable "coredns_version" {
  description = "Version of the CoreDNS addon"
  type        = string
  default     = "v1.11.1-eksbuild.9"
}

variable "vpc_cni_version" {
  description = "Version of the VPC CNI addon"
  type        = string
  default     = "v1.18.5-eksbuild.1"
}

variable "vpc_cni_service_account_role_arn" {
  description = "IAM role ARN for VPC CNI service account"
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "Version of the kube-proxy addon"
  type        = string
  default     = "v1.31.0-eksbuild.5"
}

# AWS Load Balancer Controller
variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller addon"
  type        = bool
  default     = false
}

variable "aws_load_balancer_controller_config" {
  description = "AWS Load Balancer Controller configuration"
  type = object({
    chart_version            = optional(string, "1.8.1")
    replicas                 = optional(number, 2)
    log_level                = optional(string, "info")
    service_account_role_arn = optional(string, null)
  })
  default = {}
}

# Metrics Server
variable "enable_metrics_server" {
  description = "Enable Metrics Server addon"
  type        = bool
  default     = true
}

variable "metrics_server_config" {
  description = "Metrics Server configuration"
  type = object({
    chart_version = optional(string, "3.12.1")
  })
  default = {}
}

# Cluster Autoscaler
variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler addon"
  type        = bool
  default     = true
}

variable "cluster_autoscaler_config" {
  description = "Cluster Autoscaler configuration"
  type = object({
    chart_version            = optional(string, "9.37.0")
    replicas                 = optional(number, 2)
    service_account_role_arn = optional(string, null)
  })
  default = {}
}

# AWS EFS CSI Driver
variable "enable_aws_efs_csi_driver" {
  description = "Enable AWS EFS CSI Driver addon"
  type        = bool
  default     = false
}

variable "aws_efs_csi_driver_config" {
  description = "AWS EFS CSI Driver configuration"
  type = object({
    chart_version            = optional(string, "3.0.8")
    service_account_role_arn = optional(string, null)
  })
  default = {}
}

# External DNS
variable "enable_external_dns" {
  description = "Enable External DNS addon"
  type        = bool
  default     = false
}

variable "external_dns_config" {
  description = "External DNS configuration"
  type = object({
    chart_version            = optional(string, "1.14.5")
    service_account_role_arn = optional(string, null)
    domain_filter            = optional(string, "")
  })
  default = {}
}

# External Secrets Operator
variable "enable_external_secrets" {
  description = "Enable External Secrets Operator addon"
  type        = bool
  default     = false
}

variable "external_secrets_config" {
  description = "External Secrets Operator configuration"
  type = object({
    chart_version            = optional(string, "0.10.2")
    service_account_role_arn = optional(string, null)
  })
  default = {}
}

# cert-manager
variable "enable_cert_manager" {
  description = "Enable cert-manager addon"
  type        = bool
  default     = false
}

variable "cert_manager_config" {
  description = "cert-manager configuration"
  type = object({
    chart_version            = optional(string, "v1.15.3")
    service_account_role_arn = optional(string, null)
  })
  default = {}
}

# Karpenter
variable "enable_karpenter" {
  description = "Enable Karpenter addon"
  type        = bool
  default     = false
}

variable "karpenter_config" {
  description = "Karpenter configuration"
  type = object({
    chart_version            = optional(string, "1.0.1")
    service_account_role_arn = optional(string, null)
    node_instance_profile    = optional(string, null)
    interruption_queue_name  = optional(string, null)
  })
  default = {}
}

# Vertical Pod Autoscaler
variable "enable_vpa" {
  description = "Enable Vertical Pod Autoscaler addon"
  type        = bool
  default     = false
}

variable "vpa_config" {
  description = "VPA configuration"
  type = object({
    chart_version = optional(string, "4.6.0")
  })
  default = {}
}

# AWS for FluentBit
variable "enable_aws_for_fluentbit" {
  description = "Enable AWS for FluentBit addon"
  type        = bool
  default     = false
}

variable "aws_for_fluentbit_config" {
  description = "AWS for FluentBit configuration"
  type = object({
    chart_version            = optional(string, "0.1.32")
    service_account_role_arn = optional(string, null)
    log_group_name           = optional(string, "/aws/eks/cluster/logs")
  })
  default = {}
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
