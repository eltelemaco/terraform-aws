# Security Module Outputs
# Outputs from the security module for use in other modules and infrastructure components

# Security Group Outputs
output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster additional security group"
  value       = module.eks_cluster_security_group.security_group_id
}

output "eks_cluster_security_group_arn" {
  description = "ARN of the EKS cluster additional security group"
  value       = module.eks_cluster_security_group.security_group_arn
}

output "eks_node_security_group_id" {
  description = "ID of the EKS node additional security group"
  value       = module.eks_node_security_group.security_group_id
}

output "eks_node_security_group_arn" {
  description = "ARN of the EKS node additional security group"
  value       = module.eks_node_security_group.security_group_arn
}

output "load_balancer_security_group_id" {
  description = "ID of the load balancer security group"
  value       = var.create_load_balancer_sg ? module.load_balancer_security_group[0].security_group_id : null
}

output "load_balancer_security_group_arn" {
  description = "ARN of the load balancer security group"
  value       = var.create_load_balancer_sg ? module.load_balancer_security_group[0].security_group_arn : null
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = var.create_database_sg ? module.database_security_group[0].security_group_id : null
}

output "database_security_group_arn" {
  description = "ARN of the database security group"
  value       = var.create_database_sg ? module.database_security_group[0].security_group_arn : null
}

output "efs_security_group_id" {
  description = "ID of the EFS security group"
  value       = var.create_efs_sg ? module.efs_security_group[0].security_group_id : null
}

output "efs_security_group_arn" {
  description = "ARN of the EFS security group"
  value       = var.create_efs_sg ? module.efs_security_group[0].security_group_arn : null
}

# KMS Outputs
output "kms_key_id" {
  description = "ID of the KMS key for EKS encryption"
  value       = var.create_kms_key ? aws_kms_key.eks[0].key_id : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key for EKS encryption"
  value       = var.create_kms_key ? aws_kms_key.eks[0].arn : null
}

output "kms_key_alias" {
  description = "Alias of the KMS key for EKS encryption"
  value       = var.create_kms_key ? aws_kms_alias.eks[0].name : null
}

# Network ACL Outputs
output "network_acl_id" {
  description = "ID of the network ACL for private subnets"
  value       = var.create_network_acl ? aws_network_acl.eks_private[0].id : null
}

# WAF Outputs
output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL for ALB protection"
  value       = var.create_waf_acl ? aws_wafv2_web_acl.eks_alb[0].id : null
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL for ALB protection"
  value       = var.create_waf_acl ? aws_wafv2_web_acl.eks_alb[0].arn : null
}

# GuardDuty Outputs
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.eks[0].id : null
}

# Security Recommendations
output "security_recommendations" {
  description = "Security recommendations and best practices"
  value = {
    kms_encryption_enabled      = var.create_kms_key
    network_acl_enabled         = var.create_network_acl
    waf_protection_enabled      = var.create_waf_acl
    guardduty_enabled           = var.enable_guardduty
    flow_logs_enabled           = var.enable_flow_logs
    imdsv2_enforced             = var.enforce_imdsv2
    pod_security_policy_enabled = var.enable_pod_security_policy
    network_policies_enabled    = var.enable_network_policies
    secrets_rotation_enabled    = var.enable_secrets_rotation

    recommendations = [
      "Enable VPC Flow Logs for network monitoring",
      "Implement least-privilege IAM policies",
      "Use AWS Secrets Manager for sensitive data",
      "Enable GuardDuty for threat detection",
      "Implement WAF rules for web application protection",
      "Use encrypted EBS volumes and KMS keys",
      "Enable Pod Security Policies in Kubernetes",
      "Implement Network Policies for micro-segmentation",
      "Regular security audits and compliance checks",
      "Monitor CloudTrail logs for API activity"
    ]
  }
}

# Compliance Status
output "compliance_status" {
  description = "Compliance status based on security configurations"
  value = {
    encryption_at_rest    = var.create_kms_key && var.block_device_encrypted
    encryption_in_transit = true # HTTPS enforced
    network_segmentation  = var.create_network_acl && var.enable_network_isolation
    threat_detection      = var.enable_guardduty
    access_logging        = var.enable_flow_logs
    secrets_management    = var.secrets_manager_kms_key_id != null

    compliance_score = (
      (var.create_kms_key && var.block_device_encrypted ? 20 : 0) +
      (var.create_network_acl && var.enable_network_isolation ? 20 : 0) +
      (var.enable_guardduty ? 20 : 0) +
      (var.enable_flow_logs ? 20 : 0) +
      (var.secrets_manager_kms_key_id != null ? 20 : 0)
    )

    status = (
      (var.create_kms_key && var.block_device_encrypted ? 20 : 0) +
      (var.create_network_acl && var.enable_network_isolation ? 20 : 0) +
      (var.enable_guardduty ? 20 : 0) +
      (var.enable_flow_logs ? 20 : 0) +
      (var.secrets_manager_kms_key_id != null ? 20 : 0)
    ) >= 80 ? "COMPLIANT" : "NON_COMPLIANT"
  }
}
