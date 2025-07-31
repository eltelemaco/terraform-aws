# EKS Blueprints Addons Module
# Provides enterprise-grade EKS addons using AWS-IA official module
# This module deploys essential Kubernetes addons for production workloads

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.15"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.32"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

# EKS Blueprints Addons - Official AWS module
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.22"

  cluster_name      = var.cluster_name
  cluster_endpoint  = var.cluster_endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = var.oidc_provider_arn

  # Create Kubernetes resources using Helm
  create_kubernetes_resources = true
  create_delay_duration       = "30s"

  # Core EKS Add-ons (AWS managed)
  eks_addons = var.enable_core_addons ? {
    # AWS EBS CSI Driver for persistent storage
    aws-ebs-csi-driver = {
      addon_version               = var.ebs_csi_driver_version
      service_account_role_arn    = var.ebs_csi_service_account_role_arn
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }

    # CoreDNS for cluster DNS resolution
    coredns = {
      addon_version               = var.coredns_version
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values = jsonencode({
        computeType = "Fargate"
        resources = {
          limits = {
            cpu    = "0.25"
            memory = "256M"
          }
          requests = {
            cpu    = "0.25"
            memory = "256M"
          }
        }
      })
    }

    # VPC CNI for pod networking
    vpc-cni = {
      addon_version               = var.vpc_cni_version
      service_account_role_arn    = var.vpc_cni_service_account_role_arn
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
        env = {
          ENABLE_PREFIX_DELEGATION          = "true"
          ENABLE_POD_ENI                    = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
      })
    }

    # Kube-proxy for service networking
    kube-proxy = {
      addon_version               = var.kube_proxy_version
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  } : {}

  # AWS Load Balancer Controller (if enabled separately)
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  aws_load_balancer_controller = var.enable_aws_load_balancer_controller ? {
    chart_version = var.aws_load_balancer_controller_config.chart_version
    repository    = "https://aws.github.io/eks-charts"
    namespace     = "kube-system"

    set = [
      {
        name  = "clusterName"
        value = var.cluster_name
      },
      {
        name  = "serviceAccount.create"
        value = "true"
      },
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = var.aws_load_balancer_controller_config.service_account_role_arn
      },
      {
        name  = "replicaCount"
        value = var.aws_load_balancer_controller_config.replicas
      },
      {
        name  = "logLevel"
        value = var.aws_load_balancer_controller_config.log_level
      }
    ]

    values = [
      yamlencode({
        resources = {
          requests = {
            cpu    = "100m"
            memory = "200Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "1Gi"
          }
        }

        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }

        tolerations = [
          {
            key      = "CriticalAddonsOnly"
            operator = "Exists"
          }
        ]

        podDisruptionBudget = {
          enabled        = true
          minAvailable   = 1
          maxUnavailable = null
        }
      })
    ]
  } : {}

  # Metrics Server for HPA and resource metrics
  enable_metrics_server = var.enable_metrics_server
  metrics_server = var.enable_metrics_server ? {
    chart_version = var.metrics_server_config.chart_version
    repository    = "https://kubernetes-sigs.github.io/metrics-server/"
    namespace     = "kube-system"

    values = [
      yamlencode({
        image = {
          repository = "registry.k8s.io/metrics-server/metrics-server"
        }

        args = [
          "--cert-dir=/tmp",
          "--secure-port=4443",
          "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
          "--kubelet-use-node-status-port",
          "--metric-resolution=15s"
        ]

        resources = {
          requests = {
            cpu    = "100m"
            memory = "200Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "500Mi"
          }
        }

        livenessProbe = {
          httpGet = {
            path   = "/livez"
            port   = "https"
            scheme = "HTTPS"
          }
          periodSeconds    = 10
          failureThreshold = 3
        }

        readinessProbe = {
          httpGet = {
            path   = "/readyz"
            port   = "https"
            scheme = "HTTPS"
          }
          periodSeconds    = 5
          failureThreshold = 3
        }
      })
    ]
  } : {}

  # Cluster Autoscaler for node scaling
  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  cluster_autoscaler = var.enable_cluster_autoscaler ? {
    chart_version = var.cluster_autoscaler_config.chart_version
    repository    = "https://kubernetes.github.io/autoscaler"
    namespace     = "kube-system"

    set = [
      {
        name  = "autoDiscovery.clusterName"
        value = var.cluster_name
      },
      {
        name  = "awsRegion"
        value = var.aws_region
      },
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = var.cluster_autoscaler_config.service_account_role_arn
      },
      {
        name  = "replicaCount"
        value = var.cluster_autoscaler_config.replicas
      }
    ]

    values = [
      yamlencode({
        extraArgs = {
          scale-down-delay-after-add       = "10m"
          scale-down-unneeded-time         = "10m"
          scale-down-delay-after-delete    = "10s"
          scale-down-delay-after-failure   = "3m"
          scale-down-utilization-threshold = "0.5"
          skip-nodes-with-local-storage    = "false"
          skip-nodes-with-system-pods      = "false"
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "300Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "500Mi"
          }
        }

        priorityClassName = "system-cluster-critical"

        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }

        tolerations = [
          {
            key      = "CriticalAddonsOnly"
            operator = "Exists"
          },
          {
            key    = "node-role.kubernetes.io/master"
            effect = "NoSchedule"
          }
        ]
      })
    ]
  } : {}

  # AWS EFS CSI Driver for shared storage
  enable_aws_efs_csi_driver = var.enable_aws_efs_csi_driver
  aws_efs_csi_driver = var.enable_aws_efs_csi_driver ? {
    chart_version = var.aws_efs_csi_driver_config.chart_version
    repository    = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
    namespace     = "kube-system"

    set = [
      {
        name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = var.aws_efs_csi_driver_config.service_account_role_arn
      }
    ]

    values = [
      yamlencode({
        controller = {
          resources = {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }

        node = {
          resources = {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      })
    ]
  } : {}

  # External DNS for automatic DNS management
  enable_external_dns = var.enable_external_dns
  external_dns = var.enable_external_dns ? {
    chart_version = var.external_dns_config.chart_version
    repository    = "https://kubernetes-sigs.github.io/external-dns/"
    namespace     = "kube-system"

    set = [
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = var.external_dns_config.service_account_role_arn
      },
      {
        name  = "provider"
        value = "aws"
      },
      {
        name  = "aws.region"
        value = var.aws_region
      },
      {
        name  = "domainFilters[0]"
        value = var.external_dns_config.domain_filter
      },
      {
        name  = "txtOwnerId"
        value = var.cluster_name
      }
    ]

    values = [
      yamlencode({
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }

        logLevel  = "info"
        logFormat = "json"

        policy = "upsert-only"

        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }
      })
    ]
  } : {}

  # External Secrets Operator for secret management
  enable_external_secrets = var.enable_external_secrets
  external_secrets = var.enable_external_secrets ? {
    chart_version    = var.external_secrets_config.chart_version
    repository       = "https://charts.external-secrets.io"
    namespace        = "external-secrets-system"
    create_namespace = true

    set = [
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = var.external_secrets_config.service_account_role_arn
      }
    ]

    values = [
      yamlencode({
        installCRDs = true

        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }

        webhook = {
          resources = {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }

        certController = {
          resources = {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      })
    ]
  } : {}

  # cert-manager for TLS certificate management
  enable_cert_manager = var.enable_cert_manager
  cert_manager = var.enable_cert_manager ? {
    chart_version    = var.cert_manager_config.chart_version
    repository       = "https://charts.jetstack.io"
    namespace        = "cert-manager"
    create_namespace = true

    set = [
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = var.cert_manager_config.service_account_role_arn
      },
      {
        name  = "installCRDs"
        value = "true"
      }
    ]

    values = [
      yamlencode({
        global = {
          leaderElection = {
            namespace = "cert-manager"
          }
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }

        webhook = {
          resources = {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }

        cainjector = {
          resources = {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "300m"
              memory = "512Mi"
            }
          }
        }

        startupapicheck = {
          enabled = true
          resources = {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      })
    ]
  } : {}

  # Karpenter for advanced node provisioning (optional)
  enable_karpenter = var.enable_karpenter
  karpenter = var.enable_karpenter ? {
    chart_version    = var.karpenter_config.chart_version
    repository       = "oci://public.ecr.aws/karpenter"
    namespace        = "karpenter"
    create_namespace = true

    set = [
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = var.karpenter_config.service_account_role_arn
      },
      {
        name  = "settings.clusterName"
        value = var.cluster_name
      },
      {
        name  = "settings.defaultInstanceProfile"
        value = var.karpenter_config.node_instance_profile
      },
      {
        name  = "settings.interruptionQueueName"
        value = var.karpenter_config.interruption_queue_name
      }
    ]

    values = [
      yamlencode({
        controller = {
          resources = {
            requests = {
              cpu    = "500m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }
        }

        logLevel = "info"

        webhook = {
          enabled = true
          port    = 8443
        }
      })
    ]
  } : {}

  # Vertical Pod Autoscaler
  enable_vpa = var.enable_vpa
  vpa = var.enable_vpa ? {
    chart_version    = var.vpa_config.chart_version
    repository       = "https://charts.fairwinds.com/stable"
    namespace        = "vpa-system"
    create_namespace = true

    values = [
      yamlencode({
        recommender = {
          enabled = true
          resources = {
            requests = {
              cpu    = "100m"
              memory = "500Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }
        }

        updater = {
          enabled = true
          resources = {
            requests = {
              cpu    = "100m"
              memory = "500Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }
        }

        admissionController = {
          enabled = true
          resources = {
            requests = {
              cpu    = "100m"
              memory = "200Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "500Mi"
            }
          }
        }
      })
    ]
  } : {}

  # AWS for FluentBit for log forwarding
  enable_aws_for_fluentbit = var.enable_aws_for_fluentbit
  aws_for_fluentbit = var.enable_aws_for_fluentbit ? {
    chart_version    = var.aws_for_fluentbit_config.chart_version
    repository       = "https://aws.github.io/eks-charts"
    namespace        = "amazon-cloudwatch"
    create_namespace = true

    set = [
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = var.aws_for_fluentbit_config.service_account_role_arn
      },
      {
        name  = "cloudWatch.region"
        value = var.aws_region
      },
      {
        name  = "cloudWatch.logGroupName"
        value = var.aws_for_fluentbit_config.log_group_name
      }
    ]

    values = [
      yamlencode({
        resources = {
          requests = {
            cpu    = "100m"
            memory = "200Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "500Mi"
          }
        }

        tolerations = [
          {
            key               = "node.kubernetes.io/not-ready"
            operator          = "Exists"
            effect            = "NoExecute"
            tolerationSeconds = 300
          },
          {
            key               = "node.kubernetes.io/unreachable"
            operator          = "Exists"
            effect            = "NoExecute"
            tolerationSeconds = 300
          }
        ]

        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }
      })
    ]
  } : {}

  # Tags for all resources
  tags = var.tags
}

# Create namespace for cert-manager if enabled
resource "kubernetes_namespace" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  metadata {
    name = "cert-manager"

    labels = {
      "name"                               = "cert-manager"
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

# Create namespace for external-secrets if enabled
resource "kubernetes_namespace" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  metadata {
    name = "external-secrets-system"

    labels = {
      "name"                               = "external-secrets-system"
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

# Create namespace for Karpenter if enabled
resource "kubernetes_namespace" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  metadata {
    name = "karpenter"

    labels = {
      "name"                               = "karpenter"
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

# Create namespace for VPA if enabled
resource "kubernetes_namespace" "vpa" {
  count = var.enable_vpa ? 1 : 0

  metadata {
    name = "vpa-system"

    labels = {
      "name"                               = "vpa-system"
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}
