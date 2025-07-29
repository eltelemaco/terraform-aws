# AWS Load Balancer Controller Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the EKS cluster is deployed"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy the AWS Load Balancer Controller"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account for the AWS Load Balancer Controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "create_namespace" {
  description = "Create the Kubernetes namespace if it doesn't exist"
  type        = bool
  default     = false
}

variable "helm_release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "helm_chart_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.8.1" # Latest stable version as of July 2025
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 600
}

variable "replica_count" {
  description = "Number of replicas for the AWS Load Balancer Controller"
  type        = number
  default     = 2
}

variable "cpu_request" {
  description = "CPU request for the AWS Load Balancer Controller pods"
  type        = string
  default     = "100m"
}

variable "cpu_limit" {
  description = "CPU limit for the AWS Load Balancer Controller pods"
  type        = string
  default     = "200m"
}

variable "memory_request" {
  description = "Memory request for the AWS Load Balancer Controller pods"
  type        = string
  default     = "200Mi"
}

variable "memory_limit" {
  description = "Memory limit for the AWS Load Balancer Controller pods"
  type        = string
  default     = "500Mi"
}

variable "additional_helm_values" {
  description = "Additional Helm values to pass to the AWS Load Balancer Controller chart"
  type = list(object({
    name  = string
    value = string
    type  = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
