terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Remote state — S3 + DynamoDB locking.
  # Bootstrap these manually ONCE before first terraform init (see README).
  backend "s3" {
    bucket         = "zahir-terraform-state-143575007958"
    key            = "zahir/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "zahir-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
