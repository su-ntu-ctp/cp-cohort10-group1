terraform {
  required_version = ">= 1.0"
  backend "s3" { }
    
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ShopBot"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Group1"
      Application = "E-commerce"
    }
  }
}