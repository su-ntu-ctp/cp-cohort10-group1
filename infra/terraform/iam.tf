
# ============================================================================
# IAM ROLES & POLICIES
# ============================================================================

# ECS Task Execution Role - for pulling images and logs
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.prefix}ecs-task-exec-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role - for application permissions
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}ecs-task-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# DynamoDB access policy for application
resource "aws_iam_role_policy" "app_access" {
  name = "${var.prefix}app-access-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:BatchReadItem",
          "dynamodb:DescribeTable",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.products.arn,
          aws_dynamodb_table.orders.arn,
          aws_dynamodb_table.carts.arn,
          aws_dynamodb_table.sessions.arn
        ]
      }
    ]
  })
}

# Secrets Manager access policies
resource "aws_iam_role_policy_attachment" "secrets_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# ============================================================================
# SECRETS MANAGEMENT
# ============================================================================

# Random password for session secret
resource "random_password" "session_secret" {
  length  = 32
  special = true
}

# Session secret in Secrets Manager
resource "aws_secretsmanager_secret" "session_secret" {
  name                    = "${var.prefix}session-secret-${var.environment}"
  force_overwrite_replica_secret = true
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "session_secret" {
  secret_id     = aws_secretsmanager_secret.session_secret.id
  secret_string = random_password.session_secret.result
}

# Secrets access for task role 
resource "aws_iam_role_policy_attachment" "task_secrets_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# ECR Lifecycle Policy- This helps control ECR storage costs by automatically cleaning up old images.
resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.ecr_shopbot.name

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