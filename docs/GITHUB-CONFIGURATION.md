# GitHub Repository Configuration for Multi-Account AWS Deployment

This document outlines the required GitHub repository variables, secrets, and environment configurations for the multi-account AWS deployment strategy.

## 📋 Repository Variables

Configure these variables in your GitHub repository settings (Settings → Secrets and variables → Actions → Variables):

### AWS Account Configuration

```yaml
# Production Account
PRODUCTION_AWS_ACCOUNT_ID: "123456789012"  # Replace with actual production account ID

# Non-Production Account  
NONPROD_AWS_ACCOUNT_ID: "123456789013"    # Replace with actual non-prod account ID

# Shared Services Account
SHARED_SERVICES_AWS_ACCOUNT_ID: "123456789014"  # Replace with actual shared services account ID

# Management Account (AWS Organizations)
MANAGEMENT_AWS_ACCOUNT_ID: "123456789015"  # Replace with actual management account ID

# Security Account
SECURITY_AWS_ACCOUNT_ID: "123456789016"   # Replace with actual security account ID
```

### Regional Configuration

```yaml
# Primary AWS Region
AWS_PRIMARY_REGION: "us-east-1"

# Secondary AWS Region (for disaster recovery)
AWS_SECONDARY_REGION: "us-west-2"

# Terraform Backend Region
TERRAFORM_BACKEND_REGION: "us-east-1"
```

### Terraform Configuration

```yaml
# Terraform Version
TERRAFORM_VERSION: "1.5.0"

# Terraform Backend Bucket (in shared services account)
TERRAFORM_BACKEND_BUCKET: "your-org-terraform-state-bucket"

# Terraform State Lock Table
TERRAFORM_LOCK_TABLE: "terraform-state-lock"
```

## 🔐 Repository Secrets

Configure these secrets in your GitHub repository settings (Settings → Secrets and variables → Actions → Secrets):

### AWS OIDC Configuration

```yaml
# Cross-Account Terraform Backend Role ARN (in shared services account)
TERRAFORM_BACKEND_ROLE_ARN: "arn:aws:iam::123456789014:role/GitHubActionsTerraformBackendRole"

# Optional: Fallback IAM User (not recommended for production)
AWS_ACCESS_KEY_ID: ""      # Leave empty if using OIDC
AWS_SECRET_ACCESS_KEY: ""  # Leave empty if using OIDC
```

### Notification Configuration

```yaml
# Slack Bot Token for notifications
SLACK_BOT_TOKEN: "xoxb-your-slack-bot-token"

# PagerDuty Integration Key (for production alerts)
PAGERDUTY_INTEGRATION_KEY: "your-pagerduty-integration-key"

# Teams Webhook URL (alternative to Slack)
TEAMS_WEBHOOK_URL: "https://your-org.webhook.office.com/webhookb2/..."
```

### Security & Compliance

```yaml
# Checkov API Key (for enhanced security scanning)
CHECKOV_API_KEY: "your-checkov-api-key"

# Snyk Token (for vulnerability scanning)
SNYK_TOKEN: "your-snyk-token"

# SonarCloud Token (for code quality)
SONAR_TOKEN: "your-sonarcloud-token"
```

## 🌍 Environment Configuration

Create these environments in your GitHub repository (Settings → Environments):

### Development Environment

```yaml
Name: development
Protection Rules: 
  - No protection rules required
  - Auto-deploy on push to develop branch

Environment Variables:
  AWS_ACCOUNT_ID: ${{ vars.NONPROD_AWS_ACCOUNT_ID }}
  AWS_REGION: ${{ vars.AWS_PRIMARY_REGION }}
  ENVIRONMENT: "dev"

Environment Secrets:
  # Inherit from repository secrets
```

### Staging Environment

```yaml
Name: staging
Protection Rules:
  - Require reviewers: 1
  - Wait timer: 5 minutes

Environment Variables:
  AWS_ACCOUNT_ID: ${{ vars.NONPROD_AWS_ACCOUNT_ID }}
  AWS_REGION: ${{ vars.AWS_PRIMARY_REGION }}
  ENVIRONMENT: "staging"

Environment Secrets:
  # Inherit from repository secrets
```

### Production Environment

```yaml
Name: production
Protection Rules:
  - Require reviewers: 2 (from CODEOWNERS)
  - Wait timer: 30 minutes
  - Restrict to protected branches: main

Environment Variables:
  AWS_ACCOUNT_ID: ${{ vars.PRODUCTION_AWS_ACCOUNT_ID }}
  AWS_REGION: ${{ vars.AWS_PRIMARY_REGION }}
  ENVIRONMENT: "prod"

Environment Secrets:
  # Inherit from repository secrets
```

### Production Approval Environment

```yaml
Name: production-approval
Protection Rules:
  - Require reviewers: 2 (DevOps team)
  - Restrict to protected branches: main
  - Required status checks: security-check

Environment Variables:
  # No specific variables needed

Environment Secrets:
  # Inherit from repository secrets
```

## 🏗️ AWS OIDC Provider Setup

### 1. Create OIDC Provider in Each AWS Account

Run this in each AWS account (Management, Security, Shared Services, Non-Prod, Production):

```bash
# Replace with your GitHub organization/username and repository
GITHUB_ORG="your-github-org"
GITHUB_REPO="terraform-aws"

aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 2. Create IAM Roles for GitHub Actions

#### Shared Services Account - Backend Role

```bash
# Create trust policy for GitHub Actions
cat > github-actions-backend-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789014:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name GitHubActionsTerraformBackendRole \
  --assume-role-policy-document file://github-actions-backend-trust-policy.json

# Attach policy for S3 and DynamoDB access
aws iam attach-role-policy \
  --role-name GitHubActionsTerraformBackendRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-role-policy \
  --role-name GitHubActionsTerraformBackendRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
```

#### Each Target Account - Deployment Role

```bash
# Create deployment trust policy (run in each account)
cat > github-actions-deployment-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789014:role/GitHubActionsTerraformBackendRole"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the deployment role
aws iam create-role \
  --role-name GitHubActionsDeploymentRole \
  --assume-role-policy-document file://github-actions-deployment-trust-policy.json

# Attach necessary policies (adjust based on your needs)
aws iam attach-role-policy \
  --role-name GitHubActionsDeploymentRole \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# For production, use more restrictive policies
```

## 🔧 Terraform Backend Configuration

### Shared Services Account - S3 Bucket and DynamoDB Table

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://your-org-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-org-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-org-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

## 📝 Workflow Integration

### Updated Environment Variables in Workflows

Replace hardcoded account IDs in your workflows with:

```yaml
# In terraform-dev-multiaccount.yml
aws_account_id: ${{ vars.NONPROD_AWS_ACCOUNT_ID }}

# In terraform-prod-multiaccount.yml  
aws_account_id: ${{ vars.PRODUCTION_AWS_ACCOUNT_ID }}

# In terraform-staging-multiaccount.yml
aws_account_id: ${{ vars.NONPROD_AWS_ACCOUNT_ID }}
```

### Conditional Deployments

```yaml
# Deploy to staging only from develop branch
if: github.ref == 'refs/heads/develop' && github.event_name == 'push'

# Deploy to production only from main branch with approval
if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

## 🚀 Getting Started

1. **Set up AWS accounts** following the multi-account strategy
2. **Configure OIDC providers** in each AWS account
3. **Create IAM roles** with appropriate trust relationships
4. **Set up Terraform backend** (S3 + DynamoDB) in shared services account
5. **Configure GitHub repository variables and secrets**
6. **Create GitHub environments** with protection rules
7. **Test with development environment** first
8. **Gradually roll out to staging and production**

## 🔍 Troubleshooting

### Common Issues

1. **OIDC Authentication Failures**
   - Verify thumbprint in OIDC provider
   - Check trust policy conditions
   - Ensure repository name matches exactly

2. **Cross-Account Role Assumption**
   - Verify role ARNs are correct
   - Check trust relationships between accounts
   - Ensure proper permissions on target roles

3. **Terraform Backend Access**
   - Verify S3 bucket permissions
   - Check DynamoDB table exists and is accessible
   - Ensure backend role has necessary permissions

### Debug Commands

```bash
# Test OIDC token
curl -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.amazonaws.com" | jq .

# Verify role assumption
aws sts get-caller-identity

# Check backend access
aws s3 ls s3://your-org-terraform-state-bucket
aws dynamodb describe-table --table-name terraform-state-lock
```
