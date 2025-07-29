# Dagster Data Orchestration Platform
# Comprehensive deployment for EKS with production-ready configuration

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.14"
    }
  }
}

# Dagster requires dedicated namespace for isolation
resource "kubernetes_namespace" "dagster" {
  metadata {
    name = var.namespace

    labels = {
      name                             = var.namespace
      "app.kubernetes.io/name"         = "dagster"
      "app.kubernetes.io/instance"     = var.cluster_name
      "app.kubernetes.io/managed-by"   = "terraform"
      "kubernetes.io/dagster-instance" = var.cluster_name
    }

    annotations = {
      "dagster.io/deployment" = "terraform"
      "dagster.io/cluster"    = var.cluster_name
      "dagster.io/created-by" = "terraform-aws-infrastructure"
    }
  }
}

# Dagster Service Account with IRSA for AWS integrations
resource "kubernetes_service_account" "dagster" {
  count = var.create_service_account ? 1 : 0

  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.dagster.metadata[0].name

    labels = {
      "app.kubernetes.io/name"       = "dagster"
      "app.kubernetes.io/instance"   = var.cluster_name
      "app.kubernetes.io/component"  = "service-account"
      "app.kubernetes.io/managed-by" = "terraform"
    }

    annotations = merge(
      var.service_account_annotations,
      var.enable_irsa ? {
        "eks.amazonaws.com/role-arn" = aws_iam_role.dagster[0].arn
      } : {}
    )
  }

  # Ensure namespace exists first
  depends_on = [kubernetes_namespace.dagster]
}

# IAM Role for Dagster with IRSA (if enabled)
resource "aws_iam_role" "dagster" {
  count = var.enable_irsa ? 1 : 0

  name = "${var.cluster_name}-dagster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_issuer_host}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "${var.oidc_issuer_host}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = "${var.cluster_name}-dagster-role"
    Component = "dagster"
    Purpose   = "data-orchestration"
  })
}

# IAM Policy for Dagster AWS integrations
resource "aws_iam_role_policy" "dagster" {
  count = var.enable_irsa ? 1 : 0

  name = "${var.cluster_name}-dagster-policy"
  role = aws_iam_role.dagster[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 access for data storage and compute logs
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      # CloudWatch Logs for monitoring
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/dagster/*"
      },
      # EKS access for launching job pods
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "arn:aws:eks:${var.aws_region}:*:cluster/${var.cluster_name}"
      }
    ]
  })
}

# PostgreSQL Secret for Dagster metadata storage
resource "kubernetes_secret" "dagster_postgresql" {
  count = var.create_postgresql_secret ? 1 : 0

  metadata {
    name      = "dagster-postgresql-secret"
    namespace = kubernetes_namespace.dagster.metadata[0].name

    labels = {
      "app.kubernetes.io/name"       = "dagster"
      "app.kubernetes.io/instance"   = var.cluster_name
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  type = "Opaque"

  data = {
    host     = var.postgresql_host
    port     = tostring(var.postgresql_port)
    database = var.postgresql_database
    username = var.postgresql_username
    password = var.postgresql_password
  }

  depends_on = [kubernetes_namespace.dagster]
}

# Dagster Configuration ConfigMap
resource "kubernetes_config_map" "dagster_config" {
  metadata {
    name      = "dagster-instance-config"
    namespace = kubernetes_namespace.dagster.metadata[0].name

    labels = {
      "app.kubernetes.io/name"       = "dagster"
      "app.kubernetes.io/instance"   = var.cluster_name
      "app.kubernetes.io/component"  = "config"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    "dagster.yaml" = templatefile("${path.module}/templates/dagster.yaml.tpl", {
      postgresql_host     = var.postgresql_host
      postgresql_port     = var.postgresql_port
      postgresql_database = var.postgresql_database
      postgresql_username = var.postgresql_username
      s3_bucket_name      = var.s3_bucket_name
      aws_region          = var.aws_region
      cluster_name        = var.cluster_name
      namespace           = var.namespace
      run_launcher_type   = var.run_launcher_type
      enable_s3_logs      = var.enable_s3_compute_logs
    })
  }

  depends_on = [kubernetes_namespace.dagster]
}

# Dagster Helm Release
resource "helm_release" "dagster" {
  name             = var.release_name
  namespace        = kubernetes_namespace.dagster.metadata[0].name
  create_namespace = false
  repository       = var.helm_repository
  chart            = var.helm_chart_name
  version          = var.chart_version

  # Core configuration
  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      # Basic settings
      cluster_name = var.cluster_name
      namespace    = var.namespace
      replicas     = var.replicas

      # Images
      dagster_version = var.dagster_version
      python_version  = var.python_version

      # Database configuration
      postgresql_enabled     = var.postgresql_enabled
      postgresql_host        = var.postgresql_host
      postgresql_port        = var.postgresql_port
      postgresql_database    = var.postgresql_database
      postgresql_username    = var.postgresql_username
      use_existing_secret    = var.create_postgresql_secret
      postgresql_secret_name = var.create_postgresql_secret ? kubernetes_secret.dagster_postgresql[0].metadata[0].name : ""

      # Service Account
      service_account_name   = var.service_account_name
      create_service_account = false # We create it separately

      # Resource configuration
      webserver_resources        = var.webserver_resources
      daemon_resources           = var.daemon_resources
      user_deployments_resources = var.user_deployments_resources

      # Storage configuration
      s3_bucket_name         = var.s3_bucket_name
      enable_s3_compute_logs = var.enable_s3_compute_logs

      # Run launcher configuration
      run_launcher_type       = var.run_launcher_type
      k8s_run_launcher_config = var.k8s_run_launcher_config

      # Security and networking
      ingress_enabled         = var.ingress_enabled
      ingress_host            = var.ingress_host
      ingress_class           = var.ingress_class
      enable_network_policies = var.enable_network_policies

      # Monitoring
      enable_prometheus_monitoring = var.enable_prometheus_monitoring

      # Development settings
      enable_debug_mode = var.enable_debug_mode
    })
  ]

  # Wait for dependencies
  depends_on = [
    kubernetes_namespace.dagster,
    kubernetes_service_account.dagster,
    kubernetes_config_map.dagster_config,
    kubernetes_secret.dagster_postgresql
  ]

  # Timeout for complex deployment
  timeout = 600

  # Force updates when values change
  force_update    = false
  cleanup_on_fail = true

  # Development mode settings
  wait             = true
  wait_for_jobs    = true
  disable_webhooks = false
}
