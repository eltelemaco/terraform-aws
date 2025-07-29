# Terraform AWS DevOps CI/CD Pipeline

This project implements infrastructure as code for AWS DevOps CI/CD pipelines using Terraform, Kubernetes, and Helm.

## Project Structure & Architecture

This is a Terraform-based infrastructure project targeting AWS cloud services for DevOps automation:

- **Infrastructure**: Terraform modules for AWS resources (VPC, EKS, RDS, etc.)
- **Container Orchestration**: Kubernetes deployments via EKS
- **Package Management**: Helm charts for application deployment
- **CI/CD**: Automated pipeline infrastructure for continuous deployment

## Development Workflow

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

### Essential Files & Patterns

- **`main.tf`**: Primary infrastructure definition
- **`variables.tf`**: Input variable declarations
- **`outputs.tf`**: Infrastructure output values
- **`terraform.tfvars`**: Environment-specific variable values (never commit)
- **`versions.tf`**: Provider version constraints
- **`modules/`**: Reusable Terraform modules
- **`environments/`**: Environment-specific configurations

### Security & Best Practices

- Always use `.tfvars` files for sensitive data (already gitignored)
- Pin provider versions in `versions.tf`
- Use remote state backend (S3 + DynamoDB for locking)
- Implement least-privilege IAM policies
- Tag all resources consistently for cost tracking
- Use data sources for existing AWS resources

### CI/CD Integration

- Store Terraform state remotely (never local for team projects)
- Use GitHub Actions or similar for automated terraform plan/apply
- Implement proper approval workflows for production deployments
- Run `terraform validate` and `terraform fmt` in CI pipeline

---
# Codacy Rules
Configuration for AI behavior when interacting with Codacy's MCP Server

## After ANY successful `edit_file` or `reapply` operation
- YOU MUST IMMEDIATELY run the `codacy_cli_analyze` tool from Codacy's MCP Server for each file that was edited, with:
 - `rootPath`: set to the workspace path
 - `file`: set to the path of the edited file
 - `tool`: leave empty or unset
- If any issues are found in the new edits, propose and apply fixes for them.

## CRITICAL: Dependencies and Security Checks
- IMMEDIATELY after adding Terraform providers or modules, run:
 - `codacy_cli_analyze` with `tool`: set to "trivy"
 - Check for security vulnerabilities in infrastructure code
- For Terraform-specific security:
 - Scan for hardcoded secrets, insecure configurations
 - Validate IAM policies follow least-privilege principle
 - Check for publicly accessible resources without intent

## General
- Run security analysis on all Terraform files (.tf, .tfvars templates)
- Focus on AWS security best practices and compliance
- Validate Terraform syntax and formatting
---