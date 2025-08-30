# ==============================================================================
# TERRAFORM STATE LOCKING
# ==============================================================================  

# DynamoDB table for state locking - shared across all environments
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "shopbot-terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
    Environment = "shared"
    purpose="state locking for all environmnets"
  }
}

# Store backend configuration in Secrets Manager
resource "aws_secretsmanager_secret" "terraform_backend" {
  name = "shopbot/terraform/backend-config"
}

resource "aws_secretsmanager_secret_version" "terraform_backend" {
  secret_id = aws_secretsmanager_secret.terraform_backend.id
  secret_string = jsonencode({
    bucket         = "sctp-ce10-tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
  })
}