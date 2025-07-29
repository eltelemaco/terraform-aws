# Dagster Application Module Var# Helm Chart Configuration
variable "chart_version" {
  description = "Version of the Dagster Helm chart to deploy"
  type        = string
  default     = "1.8.14" # Latest stable version
}

variable "helm_repository" {
  description = "Helm repository URL for Dagster chart"
  type        = string
  default     = "https://dagster-io.github.io/helm"
}

variable "helm_chart_name" {
  description = "Name of the Dagster Helm chart"
  type        = string
  default     = "dagster"
}

variable "dagster_version" {
  description = "Dagster application version"
  type        = string
  default     = "1.8.14"
}

variable "helm_repository" {
  description = "Helm repository URL for Dagster chart"
  type        = string
  default     = "https://dagster-io.github.io/helm"
}

variable "helm_chart_name" {
  description = "Name of the Dagster Helm chart"
  type        = string
  default     = "dagster"
}

# Configures Dagster data orchestration platform deployment on EKS

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the deployment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

# Namespace Configuration
variable "namespace" {
  description = "Kubernetes namespace for Dagster deployment"
  type        = string
  default     = "dagster"
}

variable "release_name" {
  description = "Helm release name for Dagster"
  type        = string
  default     = "dagster"
}

# Helm Chart Configuration
variable "chart_version" {
  description = "Version of the Dagster Helm chart to deploy"
  type        = string
  default     = "1.8.14" # Latest stable version
}

variable "dagster_version" {
  description = "Dagster application version"
  type        = string
  default     = "1.8.14"
}

variable "python_version" {
  description = "Python version for Dagster containers"
  type        = string
  default     = "3.11"
}

# Service Account Configuration
variable "create_service_account" {
  description = "Whether to create a service account for Dagster"
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "Name of the service account for Dagster"
  type        = string
  default     = "dagster"
}

variable "service_account_annotations" {
  description = "Additional annotations for the service account"
  type        = map(string)
  default     = {}
}

# IRSA Configuration
variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
  default     = ""
}

variable "oidc_issuer_host" {
  description = "Host part of the OIDC issuer URL (without https://)"
  type        = string
  default     = ""
}

# Database Configuration
variable "postgresql_enabled" {
  description = "Whether to deploy PostgreSQL in-cluster"
  type        = bool
  default     = true
}

variable "create_postgresql_secret" {
  description = "Whether to create PostgreSQL secret"
  type        = bool
  default     = true
}

variable "postgresql_host" {
  description = "PostgreSQL host for Dagster metadata"
  type        = string
  default     = "dagster-postgresql"
}

variable "postgresql_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "postgresql_database" {
  description = "PostgreSQL database name for Dagster"
  type        = string
  default     = "dagster"
}

variable "postgresql_username" {
  description = "PostgreSQL username for Dagster"
  type        = string
  default     = "dagster"
}

variable "postgresql_password" {
  description = "PostgreSQL password for Dagster"
  type        = string
  sensitive   = true
  default     = ""
}

# Storage Configuration
variable "s3_bucket_name" {
  description = "S3 bucket name for Dagster storage and compute logs"
  type        = string
  default     = ""
}

variable "enable_s3_compute_logs" {
  description = "Enable S3 for compute logs storage"
  type        = bool
  default     = false
}

# Run Launcher Configuration
variable "run_launcher_type" {
  description = "Type of run launcher (K8sRunLauncher or CeleryK8sRunLauncher)"
  type        = string
  default     = "K8sRunLauncher"

  validation {
    condition = contains([
      "K8sRunLauncher",
      "CeleryK8sRunLauncher"
    ], var.run_launcher_type)
    error_message = "Run launcher type must be K8sRunLauncher or CeleryK8sRunLauncher."
  }
}

variable "k8s_run_launcher_config" {
  description = "Configuration for K8s run launcher"
  type = object({
    job_namespace         = optional(string, "dagster")
    load_incluster_config = optional(bool, true)
    kubeconfig_file       = optional(string, "")
    job_image             = optional(string, "")
    image_pull_policy     = optional(string, "IfNotPresent")
    image_pull_secrets    = optional(list(string), [])
    service_account_name  = optional(string, "dagster")
    env_config_maps       = optional(list(string), [])
    env_secrets           = optional(list(string), [])
    env_vars              = optional(list(string), [])
    volume_mounts         = optional(list(string), [])
    volumes               = optional(list(string), [])
    labels                = optional(map(string), {})
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "256Mi")
      }), {})
      limits = optional(object({
        cpu    = optional(string, "500m")
        memory = optional(string, "1Gi")
      }), {})
    }), {})
  })
  default = {}
}

# Scaling Configuration
variable "replicas" {
  description = "Number of replicas for Dagster webserver"
  type        = number
  default     = 2
}

# Resource Configuration
variable "webserver_resources" {
  description = "Resource configuration for Dagster webserver"
  type = object({
    requests = optional(object({
      cpu    = optional(string, "250m")
      memory = optional(string, "512Mi")
    }), {})
    limits = optional(object({
      cpu    = optional(string, "1000m")
      memory = optional(string, "2Gi")
    }), {})
  })
  default = {
    requests = {
      cpu    = "250m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "2Gi"
    }
  }
}

variable "daemon_resources" {
  description = "Resource configuration for Dagster daemon"
  type = object({
    requests = optional(object({
      cpu    = optional(string, "250m")
      memory = optional(string, "512Mi")
    }), {})
    limits = optional(object({
      cpu    = optional(string, "500m")
      memory = optional(string, "1Gi")
    }), {})
  })
  default = {
    requests = {
      cpu    = "250m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "1Gi"
    }
  }
}

variable "user_deployments_resources" {
  description = "Resource configuration for Dagster user deployments"
  type = object({
    requests = optional(object({
      cpu    = optional(string, "100m")
      memory = optional(string, "256Mi")
    }), {})
    limits = optional(object({
      cpu    = optional(string, "500m")
      memory = optional(string, "1Gi")
    }), {})
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "1Gi"
    }
  }
}

# Networking Configuration
variable "ingress_enabled" {
  description = "Enable ingress for Dagster webserver"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Hostname for Dagster ingress"
  type        = string
  default     = ""
}

variable "ingress_class" {
  description = "Ingress class for Dagster webserver"
  type        = string
  default     = "alb"
}

variable "enable_network_policies" {
  description = "Enable Kubernetes network policies"
  type        = bool
  default     = false
}

# Monitoring Configuration
variable "enable_prometheus_monitoring" {
  description = "Enable Prometheus monitoring for Dagster"
  type        = bool
  default     = false
}

# Development Configuration
variable "enable_debug_mode" {
  description = "Enable debug mode for development"
  type        = bool
  default     = false
}

# Common Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
