
# ============================================================================
# IAM ROLES & POLICIES
# ============================================================================

# ECS Task Execution Role - for pulling images and logs
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.prefix}-ecs-task-exec-role-${var.environment}"

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
  name = "${var.prefix}-ecs-task-role-${var.environment}"

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

# ============================================================================
# 2. IAM POLICIES - Permission Definitions
# ============================================================================

# DynamoDB access policy - Application data operations
resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.prefix}-dynamodb-access-${var.environment}"
  description = "Allow CRUD operations on ShopBot DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Effect = "Allow"
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

# Secrets Manager access policy - Application secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.prefix}-secrets-access-${var.environment}"
  description = "Allow reading ShopBot application secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.session_secret.arn,
          aws_secretsmanager_secret.grafana_password.arn
        ]
      }
    ]
  })
}

# CloudWatch access policy - Monitoring and logging
resource "aws_iam_policy" "cloudwatch_read" {
  name        = "${var.prefix}-cloudwatch-read-${var.environment}"
  description = "Allow read access to CloudWatch metrics and logs for Grafana"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# 3. POLICY ATTACHMENTS - Connect Roles to Permissions
# ============================================================================

# Attach secrets access to execution role (for container startup)
resource "aws_iam_role_policy_attachment" "execution_role_secrets" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# Attach DynamoDB access to task role (for application runtime)
resource "aws_iam_role_policy_attachment" "task_role_dynamodb" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Attach secrets access to task role (for application runtime)
resource "aws_iam_role_policy_attachment" "task_role_secrets" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# Attach CloudWatch access to task role (for Grafana monitoring)
resource "aws_iam_role_policy_attachment" "task_role_cloudwatch" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.cloudwatch_read.arn
}

# ============================================================================
# ECS EXECUTE COMMAND PERMISSIONS
# ============================================================================

resource "aws_iam_role_policy_attachment" "ecs_task_ssm" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ecs_exec_policy" {
  name = "${var.prefix}-ecs-exec-policy-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel", 
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}
