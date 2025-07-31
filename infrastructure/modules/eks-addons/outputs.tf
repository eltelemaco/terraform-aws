# EKS Blueprints Addons Module Outputs
# Provides information about deployed addons and their configurations

# EKS Core Add-ons
output "eks_addons" {
  description = "Map of attributes for each EKS addon enabled"
  value       = module.eks_blueprints_addons.eks_addons
}

# AWS Load Balancer Controller
output "aws_load_balancer_controller" {
  description = "Map of attributes of the AWS Load Balancer Controller Helm release and IRSA"
  value       = module.eks_blueprints_addons.aws_load_balancer_controller
}

# Metrics Server
output "metrics_server" {
  description = "Map of attributes of the Metrics Server Helm release"
  value       = module.eks_blueprints_addons.metrics_server
}

# Cluster Autoscaler
output "cluster_autoscaler" {
  description = "Map of attributes of the Cluster Autoscaler Helm release and IRSA"
  value       = module.eks_blueprints_addons.cluster_autoscaler
}

# AWS EFS CSI Driver
output "aws_efs_csi_driver" {
  description = "Map of attributes of the AWS EFS CSI Driver Helm release and IRSA"
  value       = module.eks_blueprints_addons.aws_efs_csi_driver
}

# External DNS
output "external_dns" {
  description = "Map of attributes of the External DNS Helm release and IRSA"
  value       = module.eks_blueprints_addons.external_dns
}

# External Secrets Operator
output "external_secrets" {
  description = "Map of attributes of the External Secrets Operator Helm release and IRSA"
  value       = module.eks_blueprints_addons.external_secrets
}

# cert-manager
output "cert_manager" {
  description = "Map of attributes of the cert-manager Helm release and IRSA"
  value       = module.eks_blueprints_addons.cert_manager
}

# Karpenter
output "karpenter" {
  description = "Map of attributes of the Karpenter Helm release and IRSA"
  value       = module.eks_blueprints_addons.karpenter
}

# Vertical Pod Autoscaler
output "vpa" {
  description = "Map of attributes of the VPA Helm release"
  value       = module.eks_blueprints_addons.vpa
}

# AWS for FluentBit
output "aws_for_fluentbit" {
  description = "Map of attributes of the AWS for FluentBit Helm release and IRSA"
  value       = module.eks_blueprints_addons.aws_for_fluentbit
}

# Helm Releases (for custom releases if needed)
output "helm_releases" {
  description = "Map of attributes of the Helm releases created"
  value       = module.eks_blueprints_addons.helm_releases
}

# GitOps Bridge Metadata
output "gitops_metadata" {
  description = "GitOps Bridge metadata for ArgoCD integration"
  value       = module.eks_blueprints_addons.gitops_metadata
}

# Summary Information
output "addon_summary" {
  description = "Summary of all enabled addons"
  value = {
    core_addons = {
      enabled = var.enable_core_addons
      addons  = var.enable_core_addons ? ["aws-ebs-csi-driver", "coredns", "vpc-cni", "kube-proxy"] : []
    }
    aws_load_balancer_controller = {
      enabled = var.enable_aws_load_balancer_controller
      version = var.enable_aws_load_balancer_controller ? var.aws_load_balancer_controller_config.chart_version : null
    }
    metrics_server = {
      enabled = var.enable_metrics_server
      version = var.enable_metrics_server ? var.metrics_server_config.chart_version : null
    }
    cluster_autoscaler = {
      enabled = var.enable_cluster_autoscaler
      version = var.enable_cluster_autoscaler ? var.cluster_autoscaler_config.chart_version : null
    }
    aws_efs_csi_driver = {
      enabled = var.enable_aws_efs_csi_driver
      version = var.enable_aws_efs_csi_driver ? var.aws_efs_csi_driver_config.chart_version : null
    }
    external_dns = {
      enabled = var.enable_external_dns
      version = var.enable_external_dns ? var.external_dns_config.chart_version : null
    }
    external_secrets = {
      enabled = var.enable_external_secrets
      version = var.enable_external_secrets ? var.external_secrets_config.chart_version : null
    }
    cert_manager = {
      enabled = var.enable_cert_manager
      version = var.enable_cert_manager ? var.cert_manager_config.chart_version : null
    }
    karpenter = {
      enabled = var.enable_karpenter
      version = var.enable_karpenter ? var.karpenter_config.chart_version : null
    }
    vpa = {
      enabled = var.enable_vpa
      version = var.enable_vpa ? var.vpa_config.chart_version : null
    }
    aws_for_fluentbit = {
      enabled = var.enable_aws_for_fluentbit
      version = var.enable_aws_for_fluentbit ? var.aws_for_fluentbit_config.chart_version : null
    }
  }
}

# Namespace Information
output "namespaces_created" {
  description = "List of namespaces created by this module"
  value = concat(
    var.enable_cert_manager ? ["cert-manager"] : [],
    var.enable_external_secrets ? ["external-secrets-system"] : [],
    var.enable_karpenter ? ["karpenter"] : [],
    var.enable_vpa ? ["vpa-system"] : [],
    var.enable_aws_for_fluentbit ? ["amazon-cloudwatch"] : []
  )
}

# Service Account Role ARNs (for reference)
output "service_account_role_arns" {
  description = "Map of service account role ARNs for each addon"
  value = {
    aws_load_balancer_controller = var.enable_aws_load_balancer_controller ? var.aws_load_balancer_controller_config.service_account_role_arn : null
    cluster_autoscaler           = var.enable_cluster_autoscaler ? var.cluster_autoscaler_config.service_account_role_arn : null
    aws_efs_csi_driver           = var.enable_aws_efs_csi_driver ? var.aws_efs_csi_driver_config.service_account_role_arn : null
    external_dns                 = var.enable_external_dns ? var.external_dns_config.service_account_role_arn : null
    external_secrets             = var.enable_external_secrets ? var.external_secrets_config.service_account_role_arn : null
    cert_manager                 = var.enable_cert_manager ? var.cert_manager_config.service_account_role_arn : null
    karpenter                    = var.enable_karpenter ? var.karpenter_config.service_account_role_arn : null
    aws_for_fluentbit            = var.enable_aws_for_fluentbit ? var.aws_for_fluentbit_config.service_account_role_arn : null
    ebs_csi_driver               = var.enable_core_addons ? var.ebs_csi_service_account_role_arn : null
    vpc_cni                      = var.enable_core_addons ? var.vpc_cni_service_account_role_arn : null
  }
}
