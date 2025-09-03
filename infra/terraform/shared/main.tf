#ECR Repository- Shared accross all the environments
resource "aws_ecr_repository" "shopbot" {
  name                 = "shopbot"
  image_tag_mutability = "MUTABLE"

}

#Backend tfstate and provier config

terraform {

  backend "s3" {}
}

#AWS Provider Configuration with Shared tags

provider "aws" {
  region = "ap-southeast-1"
  default_tags {
    tags = {
      Project     = "Shopbot"
      Environment = "Shared"
      ManagedBy   = "Terraform"
      Owner       = "Group1"
      Application = "E-commerce"
    }

  }
}



# ECR Lifecycle Policy- This helps control ECR storage costs by automatically cleaning up old images.
resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.shopbot.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ==============================================================================
# TERRAFORM STATE LOCKING
# ==============================================================================  

# DynamoDB table for state locking - shared across all environments
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "shopbot-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "shared"
    purpose     = "state locking for all environmnets"
  }
}