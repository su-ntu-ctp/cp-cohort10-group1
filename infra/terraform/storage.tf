# ============================================================================
# CONTAINER REGISTRY
# ============================================================================

# Referenced to shared ECR repository
data "aws_ecr_repository" "shopbot" {
  name = "shopbot"
}

# ============================================================================
# DYNAMODB TABLES
# ============================================================================

# Products table
resource "aws_dynamodb_table" "products" {
  name         = "${var.prefix}-products-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "N"
  }
}

# Orders table
resource "aws_dynamodb_table" "orders" {
  name         = "${var.prefix}-orders-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Shopping carts table
resource "aws_dynamodb_table" "carts" {
  name         = "${var.prefix}-carts-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }
}

# User sessions table with TTL
resource "aws_dynamodb_table" "sessions" {
  name         = "${var.prefix}-sessions-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  ttl {
    attribute_name = "expires"
    enabled        = true
  }
}