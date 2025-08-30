
# Reference the DynamoDB table from shared resources
data "aws_dynamodb_table" "terraform_locks" {
  name = "shopbot-terraform-locks"
}

# Reference backend config from Secrets Manager
data "aws_secretsmanager_secret_version" "terraform_backend" {
  secret_id = "shopbot/terraform/backend-config"
}
