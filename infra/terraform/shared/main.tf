#ECR Repository- Shared accross all the environments
resource "aws_ecr_repository" "shopbot" {
  name         = "shopbot"
  image_tag_mutability = "MUTABLE"
  
}

#Backend tfstate

terraform {
  backend "s3" {
    bucket = "sctp-ce10-tfstate"
    key    = "shopbot/shared/terraform.tfstate"
    region = "ap-southeast-1"
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