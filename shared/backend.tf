# Shared Backend Configuration
# This file contains the S3 backend configuration for Terraform state management
# Copy this configuration to your environment's backend block in main.tf

# Example S3 Backend Configuration
# Uncomment and customize for your AWS account

terraform {
  # backend "s3" {
  #   bucket        = "terraform-state-bucket-unique-name"
  #   key           = "environments/ENVIRONMENT/terraform.tfstate"
  #   region        = "us-west-2"
  #   encrypt       = true
  #   use_lockfile  = true
  #   # Optional: Server-side encryption with AWS KMS
  #   # kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  #   # Optional: S3 bucket versioning (recommended)
  #   # versioning = true
  # }
}

# Prerequisites for S3 Backend
# 1. Create an S3 bucket for storing Terraform state
## No DynamoDB table required for state locking with S3 lockfile
# 3. Configure appropriate IAM permissions

# Example AWS CLI commands to set up backend resources:
# 
# # Create S3 bucket for state storage
# aws s3api create-bucket \
#   --bucket terraform-state-bucket-unique-name \
#   --region us-west-2 \
#   --create-bucket-configuration LocationConstraint=us-west-2
# 
# # Enable versioning on the S3 bucket
# aws s3api put-bucket-versioning \
#   --bucket terraform-state-bucket-unique-name \
#   --versioning-configuration Status=Enabled
# 
# # Enable server-side encryption
# aws s3api put-bucket-encryption \
#   --bucket terraform-state-bucket-unique-name \
#   --server-side-encryption-configuration '{
#     "Rules": [
#       {
#         "ApplyServerSideEncryptionByDefault": {
#           "SSEAlgorithm": "AES256"
#         }
#       }
#     ]
#   }'
# 
# # Block public access
# aws s3api put-public-access-block \
#   --bucket terraform-state-bucket-unique-name \
#   --public-access-block-configuration \
#   BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
# 


# Required IAM Permissions for Backend
# The AWS credentials used by Terraform need the following permissions:
#
# S3 Permissions:
# - s3:ListBucket
# - s3:GetObject  
# - s3:PutObject
# - s3:DeleteObject
# - s3:GetObjectVersion
# - s3:GetBucketVersioning
#

#
# Example IAM Policy:
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:ListBucket"
#       ],
#       "Resource": "arn:aws:s3:::terraform-state-bucket-unique-name"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:GetObject",
#         "s3:PutObject",
#         "s3:DeleteObject",
#         "s3:GetObjectVersion"
#       ],
#       "Resource": "arn:aws:s3:::terraform-state-bucket-unique-name/*"
#     },
#
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:ListBucket",
#         "s3:GetObject",
#         "s3:PutObject",
#         "s3:DeleteObject",
#         "s3:GetObjectVersion",
#         "s3:GetBucketVersioning"
#       ],
#       "Resource": "arn:aws:s3:::terraform-state-bucket-unique-name"
#     }
#   ]
# }

# Usage Instructions:
# 1. Set up the S3 bucket using the commands above
# 2. Update the bucket name and region in the backend configuration
# 3. Uncomment the backend block in your environment's main.tf
# 4. Run 'terraform init' to migrate to the remote backend
# 5. Verify state is stored in S3 and locking works with DynamoDB
# 5. Verify state is stored in S3 and locking works with S3 lockfile
