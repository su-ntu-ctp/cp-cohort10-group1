
# Reference the DynamoDB table from shared resources
data "aws_dynamodb_table" "terraform_locks" {
  name = "shopbot-terraform-locks"
}


