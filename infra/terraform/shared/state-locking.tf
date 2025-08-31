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