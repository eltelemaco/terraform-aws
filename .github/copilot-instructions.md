# Terraform AWS DevOps CI/CD Pipeline

This project implements infrastructure as code for AWS DevOps CI/CD pipelines using Terraform, Kubernetes, and Helm.

## Project Structure & Architecture

This is a Terraform-based infrastructure project targeting AWS cloud services for DevOps automation:

- **Infrastructure**: Terraform modules for AWS resources (VPC, EKS, RDS, etc.)
- **Container Orchestration**: Kubernetes deployments via manifest files and Helm charts
- **Package Management**: Helm charts for application deployment
- **CI/CD**: Automated pipeline infrastructure for continuous deployment with GitHub Actions

### Standard Terraform Project Structure (Updated)

```
terraform-aws/
├── infrastructure/                 # 🏗️ Core Infrastructure
│   ├── environments/              # Environment-specific configurations
│   │   ├── dev/                   # Development environment
│   │   ├── staging/               # Staging environment
│   │   └── prod/                  # Production environment (NEW)
│   ├── modules/                   # Infrastructure modules
│   │   ├── vpc/                   # VPC module
│   │   ├── eks/                   # EKS module
│   │   ├── rds/                   # RDS database module (NEW)
│   │   ├── monitoring/            # Monitoring stack module (NEW)
│   │   └── security/              # Security module
│   └── kubernetes/                # Kubernetes manifests (if needed)
├── app/                           # 🚀 Application Modules
│   ├── aws_load_balancer_controller/  # AWS Load Balancer Controller
│   └── dagster/                   # Dagster data orchestration (NEW)
├── shared/                        # Shared resources across environments
├── docs/                          # Documentation
├── .github/                       # GitHub workflows and instructions
├── DEPLOYMENT-GUIDE.md            # Complete deployment guide (NEW)
└── IMPLEMENTATION-COMPLETE.md     # Project completion summary (NEW)
```

### 🏗️ Architecture Separation

- **Infrastructure modules** (`infrastructure/modules/`): Core AWS services (VPC, EKS, RDS, Security, Monitoring)
- **Application modules** (`app/`): Application-level deployments and services (Dagster, ALB Controller)
- **Environment orchestration** (`infrastructure/environments/`): Combines both layers (dev, staging, prod)
- **Shared resources** (`shared/`): Common configurations and utilities
- **Documentation** (`docs/`): Project documentation and guides  
- **GitHub Workflows** (`.github/`): CI/CD pipeline definitions and automation
- **Kubernetes Manifests** (`infrastructure/kubernetes/`): Kubernetes manifest files for application deployment

## MCP Tools Integration

This project uses enhanced MCP tools for better development experience:

### Terraform MCP Server

- **USE FIRST**: Always use `mcp_terraform_searchModules` to find relevant Terraform modules
- **Documentation**: Use `mcp_terraform_moduleDetails` to get comprehensive module documentation
- **Policies**: Use `mcp_terraform_searchPolicies` and `mcp_terraform_policyDetails` for compliance
- **Providers**: Use `mcp_terraform_resolveProviderDocID` and `mcp_terraform_getProviderDocs` for AWS provider guidance

### Official AWS Modules (terraform-aws-modules)

**VPC Module**: `terraform-aws-modules/vpc/aws` (v6.0.1)

- 136M+ downloads - Comprehensive VPC configuration
- Supports public/private/database/elasticache/intra subnets
- NAT Gateways, Internet Gateways, VPC Endpoints
- Network ACLs, Flow Logs, IPv6 support

**EKS Module**: `terraform-aws-modules/eks/aws` (v21.0.1)

- 106M+ downloads - Complete EKS cluster management
- EKS Managed Node Groups, Self-Managed Node Groups, Fargate
- Auto Mode, Hybrid Nodes, Karpenter integration
- IAM roles, security groups, addons

### GitHub MCP Server

- **Repository Operations**: Use GitHub MCP tools for all repository interactions instead of manual Git commands
- **Pull Requests**: Use `mcp_github_create_pull_request`, `mcp_github_get_pull_request_*` tools
- **Issues Management**: Use `mcp_github_create_issue`, `mcp_github_list_issues` for project tracking
- **Workflow Management**: Use `mcp_github_list_workflows`, `mcp_github_run_workflow` for CI/CD operations

### Context7 Integration

- Enhanced code understanding and contextual suggestions
- Automatic project structure analysis
- Intelligent code completion

## Development Workflow

- ** REQUIRED**: Use Context7 for code understanding and suggestions
- ** REQUIRED**: Use MCP tools for module discovery and documentation
- ** REQUIRED**: Use GitHub MCP tools for repository operations and CI/CD management
- **Version Control**: Use GitHub for version control and collaboration
- **Branching Strategy**: Use feature branches for development, merge to main via pull requests
- **Code Reviews**: Use GitHub PR reviews for code quality and compliance checks
- **Testing**: Implement unit tests for Terraform modules using `terraform plan` and `terraform validate`
- **Documentation**: Maintain comprehensive documentation in the `docs/` directory
- **Security**: Use `mcp_terraform_searchPolicies` for compliance and security best practices
- **CI/CD**: Use GitHub Actions for automated deployments and pipeline management

### Terraform Commands

```bash
# Initialize Terraform workspace
terraform init

# Plan infrastructure changes
terraform plan -var-file="terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="terraform.tfvars"

# Destroy infrastructure (use with caution)
terraform destroy -var-file="terraform.tfvars"
```

### MCP-Enhanced Workflow with Context7

1. **Module Discovery**: Use `mcp_terraform_searchModules` before creating custom resources
2. **Documentation**: Get module details with `mcp_terraform_moduleDetails` for implementation guidance
3. **Official Modules**: Prefer terraform-aws-modules (VPC, EKS) over custom implementations
4. **Context7**: Leverage Context7 for enhanced code understanding and intelligent suggestions
5. **GitHub Integration**: Use GitHub MCP tools for repository operations, PR management, and CI/CD
6. **Security**: Leverage `mcp_terraform_searchPolicies` for compliance and security best practices

### Essential Files & Patterns (Updated)

- **`main.tf`**: Primary infrastructure definition
- **`variables.tf`**: Input variable declarations
- **`outputs.tf`**: Infrastructure output values
- **`terraform.tfvars`**: Environment-specific variable values (never commit)
- **`versions.tf`**: Provider version constraints
- **`infrastructure/modules/`**: Reusable Terraform modules
- **`infrastructure/environments/`**: Environment-specific configurations

### Multi-Environment Structure (Updated)

#### Environment Hierarchy

```
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf           # Development environment
│   │   ├── variables.tf      # Dev-specific variables
│   │   ├── terraform.tfvars  # Dev values (gitignored)
│   │   └── versions.tf       # Provider versions
│   ├── staging/
│   │   ├── main.tf           # Staging environment
│   │   ├── variables.tf      # Staging-specific variables
│   │   ├── terraform.tfvars  # Staging values (gitignored)
│   │   └── versions.tf       # Provider versions
│   └── prod/
│       ├── main.tf           # Production environment
│       ├── variables.tf      # Prod-specific variables
│       ├── terraform.tfvars  # Prod values (gitignored)
│       └── versions.tf       # Provider versions
```

#### Module Structure (Updated)

```
infrastructure/
├── modules/
│   ├── vpc/
│   │   ├── main.tf           # VPC resources using terraform-aws-modules/vpc
│   │   ├── variables.tf      # VPC module inputs
│   │   ├── outputs.tf        # VPC module outputs
│   │   └── versions.tf       # VPC module provider requirements
│   ├── eks/
│   │   ├── main.tf           # EKS resources using terraform-aws-modules/eks
│   │   ├── variables.tf      # EKS module inputs
│   │   ├── outputs.tf        # EKS module outputs
│   │   └── versions.tf       # EKS module provider requirements
│   ├── rds/
│   │   ├── main.tf           # RDS PostgreSQL with HA configuration
│   │   ├── variables.tf      # RDS module inputs
│   │   ├── outputs.tf        # RDS module outputs
│   │   └── versions.tf       # RDS module provider requirements
│   ├── monitoring/
│   │   ├── main.tf           # Prometheus/Grafana stack
│   │   ├── variables.tf      # Monitoring module inputs
│   │   ├── outputs.tf        # Monitoring module outputs
│   │   └── versions.tf       # Monitoring module provider requirements
│   └── security/
│       ├── main.tf           # Security groups, IAM roles, KMS, GuardDuty
│       ├── variables.tf      # Security module inputs
│       ├── outputs.tf        # Security module outputs
│       └── versions.tf       # Security module provider requirements
```

### Security & Best Practices

- Always use `.tfvars` files for sensitive data (already gitignored)
- Pin provider versions in `versions.tf` - use `mcp_terraform_getProviderDocs` for version guidance
- Use remote state backend (S3 + DynamoDB for locking)
- Implement least-privilege IAM policies - reference `mcp_terraform_searchPolicies` for best practices
- Tag all resources consistently for cost tracking
- Use data sources for existing AWS resources

### CI/CD Integration

- Store Terraform state remotely (never local for team projects)
- Use GitHub Actions with `mcp_github_list_workflows` and `mcp_github_run_workflow`
- Implement proper approval workflows for production deployments
- Run `terraform validate` and `terraform fmt` in CI pipeline
- Use `mcp_github_get_workflow_run_logs` for debugging failed deployments

---

# MCP Tools Usage Rules

## Terraform Development

- **ALWAYS** search for existing modules using `mcp_terraform_searchModules` before writing custom resources
- **REQUIRED**: Get module documentation with `mcp_terraform_moduleDetails` before implementing
- **SECURITY**: Check compliance policies with `mcp_terraform_searchPolicies` for critical resources
- **PROVIDERS**: Use `mcp_terraform_resolveProviderDocID` + `mcp_terraform_getProviderDocs` for AWS provider guidance

## GitHub Operations

- **REPOSITORY**: Use `mcp_github_*` tools instead of manual git commands when possible
- **PULL REQUESTS**: Always use `mcp_github_create_pull_request` for automated PR creation
- **ISSUES**: Use `mcp_github_create_issue` for tracking and `mcp_github_list_issues` for overview
- **CI/CD**: Monitor workflows with `mcp_github_list_workflows` and `mcp_github_get_workflow_run`

## Code Quality & Security with Context7

- **REQUIRED**: Use Context7 for enhanced code understanding and intelligent suggestions
- **VALIDATION**: Validate Terraform configurations before committing using Context7 analysis
- **COMPLIANCE**: Check security policies and compliance requirements using MCP tools
- **BEST PRACTICES**: Leverage Context7's automatic project structure analysis for optimal code organization
- **INTELLIGENT COMPLETION**: Use Context7's contextual suggestions for better code quality

---
# Codacy Rules
Configuration for AI behavior when interacting with Codacy's MCP Server

## using any tool that accepts the arguments: `provider`, `organization`, or `repository`
- ALWAYS use:
 - provider: gh
 - organization: eltelemaco
 - repository: terraform-aws
- Avoid calling `git remote -v` unless really necessary

## After ANY successful `edit_file` or `reapply` operation
- YOU MUST IMMEDIATELY run the `codacy_cli_analyze` tool from Codacy's MCP Server for each file that was edited, with:
 - `rootPath`: set to the workspace path
 - `file`: set to the path of the edited file
 - `tool`: leave empty or unset
- If any issues are found in the new edits, propose and apply fixes for them.
- > NOTE: Failure to follow this rule is considered a critical error.

## CRITICAL: Dependencies and Security Checks
- IMMEDIATELY after ANY of these actions:
 - Running npm/yarn/pnpm install
 - Adding dependencies to package.json
 - Adding requirements to requirements.txt
 - Adding dependencies to pom.xml
 - Adding dependencies to build.gradle
 - Any other package manager operations
- You MUST run the `codacy_cli_analyze` tool with:
 - `rootPath`: set to the workspace path
 - `tool`: set to "trivy"
 - `file`: leave empty or unset
- If any vulnerabilities are found because of the newly added packages:
 - Stop all other operations
 - Propose and apply fixes for the security issues
 - Only continue with the original task after security issues are resolved
- EXAMPLE:
 - After: npm install react-markdown
 - Do: Run codacy_cli_analyze with trivy
 - Before: Continuing with any other tasks

## General
- Repeat the relevant steps for each modified file.
- "Propose fixes" means to both suggest and, if possible, automatically apply the fixes.
- You MUST NOT wait for the user to ask for analysis or remind you to run the tool.
- Do not run `codacy_cli_analyze` looking for changes in duplicated code or code complexity metrics.
- Do not run `codacy_cli_analyze` looking for changes in code coverage.
- Do not try to manually install Codacy CLI using either brew, npm, npx, or any other package manager.
- If the Codacy CLI is not installed, just run the `codacy_cli_analyze` tool from Codacy's MCP Server.
- When calling `codacy_cli_analyze`, only send provider, organization and repository if the project is a git repository.

## Whenever a call to a Codacy tool that uses `repository` or `organization` as a parameter returns a 404 error
- Offer to run the `codacy_setup_repository` tool to add the repository to Codacy
- If the user accepts, run the `codacy_setup_repository` tool
- Do not ever try to run the `codacy_setup_repository` tool on your own
- After setup, immediately retry the action that failed (only retry once)
---
