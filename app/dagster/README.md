# Dagster Data Orchestration Platform

This Terraform module deploys [Dagster](https://dagster.io/) - a modern data orchestration platform - on Amazon EKS with production-ready configuration.

## Overview

Dagster is a cloud-native data orchestrator for the whole development lifecycle, with integrated lineage and observability, a declarative programming model, and best-in-class testability.

### Key Features

- **🚀 Production-Ready**: Optimized for EKS with proper resource limits, health checks, and scaling
- **🔐 Security-First**: IRSA integration, network policies, and proper RBAC
- **📊 Observability**: Built-in monitoring, logging, and metrics collection
- **⚡ High Availability**: Multi-replica deployment with anti-affinity rules
- **🛠 Flexible Configuration**: Support for both K8s and Celery run launchers
- **💾 Persistent Storage**: PostgreSQL for metadata, S3 for compute logs and data storage

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Dagster Platform                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Dagster UI    │  │   Dagster API   │  │   User Code     │  │
│  │   (Webserver)   │  │    (Daemon)     │  │  (Deployments)  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                   Kubernetes Run Launcher                       │
│              (Creates Pods for Each Pipeline Run)              │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   PostgreSQL    │  │   S3 Storage    │  │   CloudWatch    │  │
│  │   (Metadata)    │  │ (Compute Logs)  │  │    (Logs)       │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Requirements

### Infrastructure Prerequisites

- **EKS Cluster**: Kubernetes 1.28+ running on AWS EKS
- **VPC**: Properly configured VPC with private/public subnets
- **Security Groups**: Cluster security groups allowing required traffic
- **IAM**: OIDC provider configured for IRSA

### Resource Requirements

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| Webserver | 250m        | 512Mi          | 1000m     | 2Gi          |
| Daemon    | 250m        | 512Mi          | 500m      | 1Gi          |
| User Code | 100m        | 256Mi          | 500m      | 1Gi          |
| PostgreSQL| 250m        | 256Mi          | 500m      | 1Gi          |

### Storage Requirements

- **PostgreSQL**: 10Gi persistent volume (GP3 recommended)
- **S3 Bucket**: For compute logs and data assets (optional but recommended)

## Quick Start

### 1. Basic Deployment

```hcl
module "dagster" {
  source = "../../../app/dagster"

  # Cluster configuration
  cluster_name = "my-eks-cluster"
  aws_region   = "us-west-2"
  vpc_id       = "vpc-12345678"

  # IRSA configuration
  enable_irsa         = true
  oidc_provider_arn   = module.eks.oidc_provider_arn
  oidc_issuer_host    = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  # Storage configuration
  postgresql_enabled = true
  s3_bucket_name     = "my-dagster-storage-bucket"
  enable_s3_compute_logs = true

  tags = {
    Environment = "dev"
    Project     = "data-platform"
  }
}
```

### 2. Production Deployment

```hcl
module "dagster" {
  source = "../../../app/dagster"

  # Cluster configuration
  cluster_name = "production-eks"
  aws_region   = "us-west-2"
  vpc_id       = "vpc-12345678"

  # Scaling for production
  replicas = 3

  # Use external PostgreSQL
  postgresql_enabled = false
  postgresql_host    = "dagster-prod.cluster-xyz.us-west-2.rds.amazonaws.com"
  postgresql_database = "dagster_prod"
  postgresql_username = "dagster_user"
  postgresql_password = var.dagster_db_password

  # Production resources
  webserver_resources = {
    requests = { cpu = "500m", memory = "1Gi" }
    limits   = { cpu = "2000m", memory = "4Gi" }
  }

  daemon_resources = {
    requests = { cpu = "500m", memory = "1Gi" }
    limits   = { cpu = "1000m", memory = "2Gi" }
  }

  # Ingress configuration
  ingress_enabled = true
  ingress_host    = "dagster.company.com"
  ingress_class   = "alb"

  # Security
  enable_network_policies = true
  enable_prometheus_monitoring = true

  tags = {
    Environment = "production"
    Project     = "data-platform"
    CostCenter  = "engineering"
  }
}
```

## Configuration Options

### Run Launchers

#### K8sRunLauncher (Default)
- Each pipeline run executes in a dedicated Kubernetes pod
- Automatic cleanup of completed jobs
- Resource isolation per run
- Suitable for most workloads

#### CeleryK8sRunLauncher
- Uses Celery for distributed task execution
- Includes RabbitMQ message broker
- Better for high-throughput scenarios
- Requires additional resources

```hcl
# Enable Celery run launcher
run_launcher_type = "CeleryK8sRunLauncher"
```

### Storage Options

#### In-Cluster PostgreSQL
```hcl
postgresql_enabled = true
# PostgreSQL will be deployed in the cluster
```

#### External PostgreSQL
```hcl
postgresql_enabled = false
postgresql_host     = "your-db-host.amazonaws.com"
postgresql_database = "dagster"
postgresql_username = "dagster_user"
postgresql_password = var.db_password
```

#### S3 Storage
```hcl
s3_bucket_name = "your-dagster-bucket"
enable_s3_compute_logs = true
```

### Resource Customization

```hcl
webserver_resources = {
  requests = {
    cpu    = "500m"
    memory = "1Gi"
  }
  limits = {
    cpu    = "2000m"
    memory = "4Gi"
  }
}
```

## Accessing Dagster

### Port Forward (Development)
```bash
kubectl port-forward -n dagster service/dagster-dagster-webserver 8080:80
```
Access at: http://localhost:8080

### Ingress (Production)
Configure ingress with your domain:
```hcl
ingress_enabled = true
ingress_host    = "dagster.yourdomain.com"
```

## Monitoring and Observability

### Viewing Logs
```bash
# Webserver logs
kubectl logs -n dagster deployment/dagster-dagster-webserver -f

# Daemon logs
kubectl logs -n dagster deployment/dagster-dagster-daemon -f

# User code logs
kubectl logs -n dagster deployment/dagster-user-code -f
```

### Health Checks
```bash
# Check pod status
kubectl get pods -n dagster -l app.kubernetes.io/name=dagster

# Check service endpoints
kubectl get services -n dagster

# Check ingress (if enabled)
kubectl get ingress -n dagster
```

### Prometheus Monitoring
```hcl
enable_prometheus_monitoring = true
```

## Security Configuration

### IRSA (IAM Roles for Service Accounts)
Automatically configured when `enable_irsa = true`:
- Creates IAM role with S3 and CloudWatch permissions
- Configures trust relationship with OIDC provider
- Annotates service account with role ARN

### Network Policies
```hcl
enable_network_policies = true
```
Restricts network traffic to necessary communications only.

### Resource Security
- Non-root containers
- Security contexts configured
- Resource limits enforced
- Least-privilege IAM policies

## Troubleshooting

### Common Issues

#### PostgreSQL Connection Issues
```bash
# Check PostgreSQL pod
kubectl get pods -n dagster -l app.kubernetes.io/name=postgresql

# Check PostgreSQL logs
kubectl logs -n dagster deployment/dagster-postgresql -f

# Test connection
kubectl exec -n dagster deployment/dagster-dagster-webserver -- pg_isready -h dagster-postgresql -p 5432
```

#### Pod Scheduling Issues
```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pods -n dagster

# Check resource quotas
kubectl get resourcequota -n dagster
```

#### IRSA Issues
```bash
# Check service account annotations
kubectl get serviceaccount -n dagster dagster -o yaml

# Check IAM role trust policy
aws iam get-role --role-name <cluster-name>-dagster-role
```

### Performance Tuning

#### Resource Optimization
- Monitor CPU/memory usage: `kubectl top pods -n dagster`
- Adjust resource requests/limits based on actual usage
- Consider node placement and affinity rules

#### Database Performance
- Monitor PostgreSQL metrics
- Consider using external RDS for production
- Tune PostgreSQL configuration for workload

#### Storage Performance
- Use GP3 storage class for better IOPS
- Consider S3 Transfer Acceleration for large datasets
- Monitor S3 request patterns and costs

## Backup and Recovery

### Database Backups
```bash
# Create PostgreSQL backup
kubectl exec -n dagster deployment/dagster-postgresql -- pg_dump -U dagster dagster > backup.sql

# Restore from backup
kubectl exec -i -n dagster deployment/dagster-postgresql -- psql -U dagster dagster < backup.sql
```

### Configuration Backups
```bash
# Export Helm values
helm get values dagster -n dagster > dagster-values-backup.yaml

# Export Kubernetes manifests
kubectl get all -n dagster -o yaml > dagster-k8s-backup.yaml
```

## Upgrading Dagster

### Minor Version Updates
```bash
# Update Helm chart
helm repo update dagster
helm upgrade dagster dagster/dagster -n dagster -f values.yaml
```

### Major Version Updates
1. Review [Dagster migration guide](https://docs.dagster.io/deployment/migration)
2. Test upgrade in development environment
3. Backup database and configuration
4. Perform staged upgrade with proper validation

## Contributing

When contributing to this module:

1. Follow Terraform best practices
2. Update documentation for any new variables
3. Test with multiple Dagster versions
4. Validate security configurations
5. Test resource scaling scenarios

## References

- [Dagster Documentation](https://docs.dagster.io/)
- [Dagster Kubernetes Deployment](https://docs.dagster.io/deployment/kubernetes)
- [Dagster Helm Chart](https://github.com/dagster-io/dagster/tree/master/helm/dagster)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## Support

For issues and questions:
- Check the [troubleshooting section](#troubleshooting)
- Review Dagster community resources
- File issues in the project repository
