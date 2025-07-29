# Terraform AWS DevOps CI/CD Pipeline

This project implements infrastructure as code for AWS DevOps CI/CD pipelines using Terraform, Kubernetes, and Helm.

## 🏗️ Architecture

- **VPC**: Custom VPC with public/private subnets across multiple AZs
- **EKS**: Managed Kubernetes cluster for container orchestration
- **Node Groups**: Auto-scaling worker nodes for application workloads
- **Security**: Least-privilege IAM roles and security groups
- **State Management**: Remote state storage with locking

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- kubectl installed for cluster management

### Deployment Steps

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd # Terraform AWS Infrastructure

A production-ready Terraform project following best practices for multi-environment AWS infrastructure deployment. This project implements a modular architecture using official terraform-aws-modules for reliability and maintainability.

## 🏗️ Architecture Overview

This infrastructure setup provides:
- **Multi-environment support** (development, staging, production)
- **Modular design** with reusable components
- **VPC networking** with public/private subnets across multiple AZs
- **EKS Kubernetes clusters** with managed node groups
- **Security best practices** with proper IAM roles and security groups
- **Monitoring and logging** with CloudWatch integration
- **Production-ready addons** and configurations

## 📁 Project Structure

```
terraform-aws/
├── infrastructure/               # 🏗️ Core Infrastructure
│   ├── environments/            # Environment-specific configurations
│   │   ├── dev/                 # Development environment
│   │   ├── staging/             # Staging environment
│   │   └── prod/                # Production environment
│   └── modules/                 # Infrastructure modules
│       ├── vpc/                 # VPC networking module
│       ├── eks/                 # EKS cluster module
│       └── security/            # Security groups, IAM roles
├── app/                         # 🚀 Application Modules
│   └── aws_load_balancer_controller/  # AWS Load Balancer Controller
├── shared/                      # Shared configurations
│   └── backend.tf               # Remote state backend configuration
└── .github/
    └── copilot-instructions.md  # AI coding guidelines with MCP integration
```

### 🏗️ Infrastructure vs Application Separation

- **Infrastructure modules** (`infrastructure/modules/`): Core AWS services (VPC, EKS, Security)
- **Application modules** (`app/`): Application-level deployments (Load Balancers, Services)
- **Environment configs** (`infrastructure/environments/`): Orchestrate both infrastructure and applications

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** (>= 1.0) installed
3. **kubectl** installed for cluster management
4. **Appropriate IAM permissions** for EKS and VPC management

### Deployment Steps

1. **Clone and navigate to the repository:**
   ```bash
   git clone <repository-url>
   cd terraform-aws
   ```

2. **Choose your environment** (dev/staging/prod):
   ```bash
   cd environments/dev  # or staging
   ```

3. **Configure your variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

4. **Initialize and deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Configure kubectl access:**
   ```bash
   aws eks --region us-west-2 update-kubeconfig --name dev-eks-cluster
   ```

## 🏭 Environments

### Development Environment
- **Purpose**: Developer testing and feature development
- **Configuration**: Cost-optimized with minimal resources
- **CIDR**: 10.0.0.0/16
- **Features**: Single NAT gateway, basic logging, t3.medium instances

### Staging Environment  
- **Purpose**: Pre-production testing and validation
- **Configuration**: Production-like setup for realistic testing
- **CIDR**: 10.1.0.0/16
- **Features**: Multi-AZ NAT gateways, comprehensive logging, mixed instance types

### Production Environment
- **Purpose**: Live production workloads
- **Configuration**: High availability, security, and performance optimized
- **CIDR**: 10.2.0.0/16 (planned)
- **Features**: Full encryption, enhanced monitoring, auto-scaling

## 🧩 Modules

### VPC Module (`modules/vpc/`)
Based on [terraform-aws-modules/vpc](https://github.com/terraform-aws-modules/vpc) (136M+ downloads)

**Features:**
- Multi-AZ public and private subnets
- NAT gateways for outbound internet access
- VPC Flow Logs for network monitoring
- Database and ElastiCache subnet groups
- Comprehensive tagging strategy

### EKS Module (`modules/eks/`)
Based on [terraform-aws-modules/eks](https://github.com/terraform-aws-modules/eks) (106M+ downloads)

**Features:**
- Managed EKS cluster with configurable Kubernetes version
- Multiple managed node groups with auto-scaling
- Essential addons (CoreDNS, VPC CNI, EBS CSI, etc.)
- IRSA (IAM Roles for Service Accounts) enabled
- Comprehensive logging and monitoring
- KMS encryption support

## 🔧 Configuration

### Environment Variables
Each environment supports extensive customization through variables:

- **Networking**: VPC CIDR, subnet configurations, NAT gateway settings
- **Compute**: Instance types, scaling parameters, node group configurations
- **Security**: Endpoint access, encryption settings, IAM configurations
- **Monitoring**: Log retention, flow logs, CloudWatch settings

### Remote State Management
Configure remote state backend in `shared/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket        = "your-terraform-state-bucket"
    key           = "environments/dev/terraform.tfstate"
    region        = "us-west-2"
    encrypt       = true
    use_lockfile  = true
  }
}
```

## 🛡️ Security Features

- **Network Segmentation**: Private subnets for worker nodes
- **IAM Best Practices**: Least privilege access with dedicated roles
- **Encryption**: KMS encryption for EKS secrets (configurable)
- **Access Control**: EKS access entries for fine-grained permissions
- **Flow Logs**: VPC traffic monitoring and analysis
- **Security Groups**: Minimal required access rules

## 📊 Monitoring & Logging

- **EKS Control Plane Logs**: API, audit, authenticator, controller manager, scheduler
- **VPC Flow Logs**: Network traffic analysis
- **CloudWatch Integration**: Centralized logging and metrics
- **Configurable Retention**: Adjust log retention based on environment needs

## 🎯 Best Practices Implemented

### Terraform Best Practices
- ✅ **Modular Architecture**: Reusable modules for different components
- ✅ **Environment Separation**: Isolated state and configurations
- ✅ **Version Pinning**: Specific provider and module versions
- ✅ **Remote State**: Centralized state management with locking
- ✅ **Consistent Tagging**: Comprehensive resource tagging strategy

### AWS Best Practices
- ✅ **Multi-AZ Deployment**: High availability across availability zones
- ✅ **Security Groups**: Principle of least privilege
- ✅ **IAM Roles**: Service-specific roles with minimal permissions
- ✅ **Encryption**: Data encryption at rest and in transit
- ✅ **Logging**: Comprehensive audit and operational logging

### EKS Best Practices
- ✅ **Managed Node Groups**: AWS-managed worker nodes
- ✅ **Private Networking**: Worker nodes in private subnets
- ✅ **IRSA**: Secure pod-to-AWS service authentication
- ✅ **Essential Addons**: Production-ready cluster components
- ✅ **Multi-Node Groups**: Workload-specific node configurations

## 🔍 Troubleshooting

### Common Issues

1. **IAM Permissions**: Ensure your AWS credentials have sufficient permissions
2. **CIDR Conflicts**: Verify VPC CIDRs don't overlap with existing networks
3. **Resource Limits**: Check AWS service quotas for your account
4. **Terraform State**: Use `terraform state` commands for state management

### Useful Commands

```bash
# Check cluster status
kubectl cluster-info

# View terraform state
terraform state list

# Check AWS resources
aws eks describe-cluster --name dev-eks-cluster

# Debug networking
kubectl get nodes -o wide
```

## 🛠️ Development Workflow

### Using MCP Tools
This project is enhanced with Model Context Protocol (MCP) tools for improved development:

- **Context7**: Access to official Terraform documentation and modules
- **Terraform MCP**: Direct access to Terraform registry and best practices
- **GitHub MCP**: Repository management and CI/CD integration


### AI-Assisted Development
See `.github/copilot-instructions.md` for AI coding guidelines that leverage MCP tools for:
- Module discovery and implementation
- Best practice validation
- Documentation generation
- Troubleshooting assistance

## 🧠 MCP Tools Integration

This project is fully integrated with Model Context Protocol (MCP) servers for enhanced infrastructure-as-code development, automation, and security. The following MCP servers are configured in `.vscode/mcp.json`:

- **Context7**: Official Terraform documentation, module discovery, and contextual code suggestions
- **Terraform MCP**: Direct access to Terraform Registry modules, providers, and best practices
- **GitHub MCP**: Repository management, pull requests, issues, and CI/CD workflow automation
- **Codacy MCP**: Automated code quality and security analysis (requires API token)

### 🚦 Onboarding & Usage

1. **Ensure MCP servers are configured**
   - See `.vscode/mcp.json` for server endpoints and authentication
   - Codacy requires a valid API token for security scans

2. **Module Discovery & Implementation**
   - Use `mcp_terraform_searchModules` to find official modules (e.g., VPC, EKS)
   - Retrieve documentation with `mcp_terraform_moduleDetails` before implementation
   - Prefer `terraform-aws-modules` for AWS resources

3. **Provider & Policy Guidance**
   - Use `mcp_terraform_resolveProviderDocID` and `mcp_terraform_getProviderDocs` for AWS provider best practices
   - Check compliance/security with `mcp_terraform_searchPolicies` and `mcp_terraform_policyDetails`

4. **Repository & CI/CD Automation**
   - Use GitHub MCP tools for pull requests, issues, and workflow management (`mcp_github_*`)
   - Monitor and trigger workflows with `mcp_github_list_workflows` and `mcp_github_run_workflow`

5. **Security & Quality**
   - After editing Terraform files, run Codacy analysis for code quality and security (`codacy_cli_analyze`)
   - Run with `tool: "trivy"` for infrastructure security scanning
   - Address any issues or vulnerabilities before merging changes

6. **Best Practices**
   - Always use `.tfvars` for sensitive data (never commit)
   - Pin provider/module versions in `versions.tf`
   - Use remote state backend (S3 with lockfile)
   - Tag all resources for cost tracking
   - Validate and format Terraform code before commit

For detailed AI/MCP coding rules, see `.github/copilot-instructions.md`.

## 📚 Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [terraform-aws-modules/vpc](https://github.com/terraform-aws-modules/vpc)
- [terraform-aws-modules/eks](https://github.com/terraform-aws-modules/eks)

## 🤝 Contributing

1. Follow the established module structure
2. Use the MCP-enhanced workflow described in `.github/copilot-instructions.md`
3. Test changes in development environment first
4. Update documentation for any new features
5. Follow Terraform formatting standards (`terraform fmt`)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
   ```

2. **Configure Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan Infrastructure**
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

5. **Deploy Infrastructure**
   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

6. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --region <your-region> --name <cluster-name>
   ```

## 📁 Project Structure

```
infrastructure/
├── main.tf                    # Provider configurations and data sources
├── versions.tf                # Terraform and provider version constraints
├── variables.tf               # Input variable declarations
├── outputs.tf                 # Infrastructure output values
├── infrastructure.tf          # Module calls for main infrastructure
├── terraform.tfvars.example   # Example variable values
├── modules/
│   ├── vpc/                  # VPC module for networking
│   └── eks/                  # EKS module for Kubernetes cluster
└── .github/
    └── copilot-instructions.md # AI coding guidelines
```

## 🔧 Configuration

### Environment Variables

Copy `terraform.tfvars.example` to `terraform.tfvars` and customize:

- `project_name`: Your project identifier
- `environment`: Target environment (dev/staging/prod)
- `aws_region`: AWS region for deployment
- `vpc_cidr`: Network CIDR block
- `cluster_name`: EKS cluster name

### Remote State Backend

Configure S3 backend in `versions.tf`:

```hcl
backend "s3" {
  bucket        = "your-terraform-state-bucket"
  key           = "terraform.tfstate"
  region        = "us-west-2"
  encrypt       = true
  use_lockfile  = true
}
```

## 🛡️ Security

- IAM roles follow least-privilege principle
- VPC with private subnets for worker nodes
- Security groups with minimal required access
- Encrypted state storage
- Resource tagging for cost tracking

## 🔄 CI/CD Integration

This infrastructure supports CI/CD pipelines with:

- GitHub Actions workflows
- Automated terraform plan/apply
- Multi-environment deployments
- Approval workflows for production

## 📖 Next Steps

1. **Add Application Modules**: Create modules for your specific applications
2. **Configure Monitoring**: Add CloudWatch, Prometheus, or Grafana
3. **Setup CI/CD**: Configure GitHub Actions or similar pipeline
4. **Database Integration**: Add RDS or other database services
5. **Networking**: Configure load balancers and ingress controllers

## 🤝 Contributing

Please follow the AI coding guidelines in `.github/copilot-instructions.md` when making changes to this project.

## 📋 Commands Reference

```bash
# Terraform workflow
terraform init                              # Initialize workspace
terraform plan -var-file="terraform.tfvars" # Plan changes
terraform apply -var-file="terraform.tfvars"# Apply changes
terraform destroy -var-file="terraform.tfvars" # Destroy (caution!)

# Kubernetes management
kubectl get nodes                           # Check node status
kubectl get pods --all-namespaces          # Check all pods
helm list --all-namespaces                 # List Helm releases
```
