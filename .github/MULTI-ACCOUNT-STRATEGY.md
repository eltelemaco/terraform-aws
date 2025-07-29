# Multi-Account AWS Deployment Strategy

## 📋 **Recommended Multi-Account Architecture**

### 🏗️ **Account Structure**

```
AWS Organization
├── 🏢 Management Account (Root)
│   ├── AWS Organizations
│   ├── Billing & Cost Management
│   ├── CloudTrail (Organization Trail)
│   └── AWS Config (Organization Rules)
│
├── 🔒 Security Account
│   ├── AWS Security Hub
│   ├── GuardDuty (Delegated Admin)
│   ├── AWS Config (Aggregator)
│   ├── CloudTrail Logs
│   └── KMS Keys (Cross-Account)
│
├── 📊 Shared Services Account
│   ├── Route 53 (DNS)
│   ├── AWS Certificate Manager
│   ├── ECR (Container Registry)
│   ├── S3 (Terraform State Backend)
│   └── DynamoDB (State Locking)
│
├── 🚀 Non-Production Account
│   ├── Development Environment
│   ├── Staging Environment
│   ├── Testing Environment
│   └── Integration Environment
│
└── 🏭 Production Account
    ├── Production Environment
    ├── DR/Backup Environment
    └── Production Support Tools
```

### 🎯 **Benefits of This Approach**

1. **🛡️ Security Isolation**: Production completely isolated from non-prod
2. **💰 Cost Management**: Clear billing separation and cost allocation
3. **🔐 Access Control**: Fine-grained IAM permissions per account
4. **📊 Compliance**: Easier audit trails and compliance reporting
5. **🔄 Blast Radius**: Issues in dev/staging won't affect production
6. **📈 Scalability**: Easy to add new environments or accounts

## 🔧 **Implementation Strategy**

### **Phase 1: Account Setup & Organization**
### **Phase 2: Cross-Account IAM Roles**
### **Phase 3: Terraform Backend Configuration**
### **Phase 4: GitHub Actions Integration**
### **Phase 5: Monitoring & Compliance**

---

## 🚀 **Phase 1: Account Setup & Organization**

### 1.1 Create AWS Organization Structure
```bash
# Using AWS CLI or Management Console
aws organizations create-organization --feature-set ALL

# Create Organizational Units
aws organizations create-organizational-unit \
    --parent-id r-xxxx \
    --name "Production"

aws organizations create-organizational-unit \
    --parent-id r-xxxx \
    --name "Non-Production"

aws organizations create-organizational-unit \
    --parent-id r-xxxx \
    --name "Security"
```

### 1.2 Account Configuration
| Account | Purpose | Environment | Region Strategy |
|---------|---------|-------------|----------------|
| **Management** | AWS Organizations, Billing | - | us-east-1 |
| **Security** | Security monitoring, compliance | - | us-east-1, us-west-2 |
| **Shared Services** | DNS, ECR, Terraform state | - | us-east-1, us-west-2 |
| **Non-Production** | Dev, staging, testing | dev, staging | us-east-1 |
| **Production** | Live workloads | prod | us-east-1, us-west-2 |

---

## 🔐 **Phase 2: Cross-Account IAM Roles**

### 2.1 Create Cross-Account Deployment Roles

```hcl
# shared-services/iam-cross-account-roles.tf
# Terraform State Backend Access Role
resource "aws_iam_role" "terraform_backend_role" {
  name = "TerraformBackendRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.nonprod_account_id}:root",
            "arn:aws:iam::${var.prod_account_id}:root"
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })
}

# Deployment Role for Non-Production Account
resource "aws_iam_role" "nonprod_deployment_role" {
  provider = aws.nonprod
  name     = "GitHubActionsDeploymentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.nonprod_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# Deployment Role for Production Account
resource "aws_iam_role" "prod_deployment_role" {
  provider = aws.prod
  name     = "GitHubActionsDeploymentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.prod_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}
```

---

## 🗄️ **Phase 3: Terraform Backend Configuration**

### 3.1 Centralized State Backend in Shared Services Account

```hcl
# shared-services/terraform-backend.tf
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-${var.organization_name}-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "TerraformStateLock"
    Environment = "shared"
    Purpose     = "terraform-state-locking"
  }
}
```

### 3.2 Environment-Specific Backend Configuration

```hcl
# infrastructure/environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-myorg-abc123"
    key            = "nonprod/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    role_arn       = "arn:aws:iam::SHARED-SERVICES-ACCOUNT:role/TerraformBackendRole"
  }
}

# infrastructure/environments/staging/backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-myorg-abc123"
    key            = "nonprod/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    role_arn       = "arn:aws:iam::SHARED-SERVICES-ACCOUNT:role/TerraformBackendRole"
  }
}

# infrastructure/environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-myorg-abc123"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    role_arn       = "arn:aws:iam::SHARED-SERVICES-ACCOUNT:role/TerraformBackendRole"
  }
}
```

---

## 🔄 **Phase 4: GitHub Actions Integration**

### 4.1 Updated Reusable Workflow with Multi-Account Support
