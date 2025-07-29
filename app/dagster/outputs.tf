# Dagster Application Module Outputs
# Provides essential information about the deployed Dagster infrastructure

# Namespace Information
output "namespace" {
  description = "Kubernetes namespace where Dagster is deployed"
  value       = kubernetes_namespace.dagster.metadata[0].name
}

output "namespace_labels" {
  description = "Labels applied to the Dagster namespace"
  value       = kubernetes_namespace.dagster.metadata[0].labels
}

# Service Account Information
output "service_account_name" {
  description = "Name of the Dagster service account"
  value       = var.create_service_account ? kubernetes_service_account.dagster[0].metadata[0].name : var.service_account_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for Dagster (if IRSA is enabled)"
  value       = var.enable_irsa ? aws_iam_role.dagster[0].arn : null
}

output "iam_role_name" {
  description = "Name of the IAM role for Dagster (if IRSA is enabled)"
  value       = var.enable_irsa ? aws_iam_role.dagster[0].name : null
}

# Helm Release Information
output "helm_release_name" {
  description = "Name of the Dagster Helm release"
  value       = helm_release.dagster.name
}

output "helm_release_namespace" {
  description = "Namespace of the Dagster Helm release"
  value       = helm_release.dagster.namespace
}

output "helm_release_version" {
  description = "Version of the deployed Dagster Helm chart"
  value       = helm_release.dagster.version
}

output "helm_release_status" {
  description = "Status of the Dagster Helm release"
  value       = helm_release.dagster.status
}

# Database Configuration
output "postgresql_secret_name" {
  description = "Name of the PostgreSQL secret (if created)"
  value       = var.create_postgresql_secret ? kubernetes_secret.dagster_postgresql[0].metadata[0].name : null
}

output "postgresql_endpoint" {
  description = "PostgreSQL endpoint for Dagster"
  value       = "${var.postgresql_host}:${var.postgresql_port}/${var.postgresql_database}"
}

# Configuration Information
output "config_map_name" {
  description = "Name of the Dagster configuration ConfigMap"
  value       = kubernetes_config_map.dagster_config.metadata[0].name
}

# Access Information
output "webserver_service_name" {
  description = "Name of the Dagster webserver service"
  value       = "${var.release_name}-dagster-webserver"
}

output "webserver_port" {
  description = "Port for the Dagster webserver service"
  value       = 80
}

output "ingress_hostname" {
  description = "Hostname for Dagster webserver access (if ingress enabled)"
  value       = var.ingress_enabled && var.ingress_host != "" ? var.ingress_host : null
}

# Storage Configuration
output "s3_bucket_name" {
  description = "S3 bucket name for Dagster storage (if configured)"
  value       = var.s3_bucket_name != "" ? var.s3_bucket_name : null
}

output "compute_logs_enabled" {
  description = "Whether S3 compute logs are enabled"
  value       = var.enable_s3_compute_logs
}

# Run Launcher Configuration
output "run_launcher_type" {
  description = "Type of run launcher configured for Dagster"
  value       = var.run_launcher_type
}

# Resource Information
output "webserver_resources" {
  description = "Resource configuration for Dagster webserver"
  value       = var.webserver_resources
}

output "daemon_resources" {
  description = "Resource configuration for Dagster daemon"
  value       = var.daemon_resources
}

# Monitoring Configuration
output "prometheus_monitoring_enabled" {
  description = "Whether Prometheus monitoring is enabled"
  value       = var.enable_prometheus_monitoring
}

# Development Configuration
output "debug_mode_enabled" {
  description = "Whether debug mode is enabled"
  value       = var.enable_debug_mode
}

# kubectl commands for easy access
output "kubectl_get_pods" {
  description = "Command to get Dagster pods"
  value       = "kubectl get pods -n ${kubernetes_namespace.dagster.metadata[0].name} -l app.kubernetes.io/name=dagster"
}

output "kubectl_get_services" {
  description = "Command to get Dagster services"
  value       = "kubectl get services -n ${kubernetes_namespace.dagster.metadata[0].name}"
}

output "kubectl_port_forward" {
  description = "Command to port-forward to Dagster webserver"
  value       = "kubectl port-forward -n ${kubernetes_namespace.dagster.metadata[0].name} service/${var.release_name}-dagster-webserver 8080:80"
}

output "kubectl_logs_webserver" {
  description = "Command to view Dagster webserver logs"
  value       = "kubectl logs -n ${kubernetes_namespace.dagster.metadata[0].name} deployment/${var.release_name}-dagster-webserver -f"
}

output "kubectl_logs_daemon" {
  description = "Command to view Dagster daemon logs"
  value       = "kubectl logs -n ${kubernetes_namespace.dagster.metadata[0].name} deployment/${var.release_name}-dagster-daemon -f"
}

# Dagster UI Access
output "dagster_ui_url" {
  description = "URL to access Dagster UI (use with port-forward or ingress)"
  value       = var.ingress_enabled && var.ingress_host != "" ? "https://${var.ingress_host}" : "http://localhost:8080 (use kubectl port-forward)"
}

# Helm Commands
output "helm_status_command" {
  description = "Command to check Helm release status"
  value       = "helm status ${helm_release.dagster.name} -n ${helm_release.dagster.namespace}"
}

output "helm_upgrade_command" {
  description = "Command to upgrade Dagster Helm release"
  value       = "helm upgrade ${helm_release.dagster.name} dagster/dagster -n ${helm_release.dagster.namespace} -f values.yaml"
}
