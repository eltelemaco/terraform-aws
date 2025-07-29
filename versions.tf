terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }

  # Configure remote state backend
  backend "s3" {
    # These values should be provided via backend config file or CLI
    # bucket = "your-terraform-state-bucket"
    # key    = "terraform.tfstate"
    # region = "us-west-2"
    # dynamodb_table = "terraform-locks"
    # encrypt = true
  }
}
