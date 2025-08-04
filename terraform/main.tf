

# VPC 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "shopbot-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_support = true
  enable_dns_hostnames = true

}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.prefix}alb-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# App Security Group
resource "aws_security_group" "app_sg" {
  name_prefix = "${var.prefix}app-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ECR repository
resource "aws_ecr_repository" "ecr_shopbot" {
  name         = "${var.prefix}ecr"
  force_delete = true
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.prefix}ecs-task-exec-role"

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

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}ecs-task-role"

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

# DynamoDB Tables
resource "aws_dynamodb_table" "products" {
  name           = "${var.prefix}products"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "orders" {
  name           = "${var.prefix}orders"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "carts" {
  name           = "${var.prefix}carts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# IAM Policy for DynamoDB 
resource "aws_iam_role_policy" "app_access" {
  name = "${var.prefix}app-access"
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
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.products.arn,
          aws_dynamodb_table.orders.arn,
          aws_dynamodb_table.carts.arn
        ]
      }
    ]
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.prefix}ecs"
}


# ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.prefix}app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.prefix}container"
      image = "${aws_ecr_repository.ecr_shopbot.repository_url}:latest"
      
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "NODE_ENV"
          value = "${var.environment}"
        },
        {
          name  = "PORT"
          value = "3000"
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "PRODUCTS_TABLE"
          value = aws_dynamodb_table.products.name
        },
        {
          name  = "ORDERS_TABLE"
          value = aws_dynamodb_table.orders.name
        },
        {
          name  = "CARTS_TABLE"
          value = aws_dynamodb_table.carts.name
        },
        secrets = [
        {
          name = "SESSION_SECRET"
          valueFrom = aws_secretsmanager_secret.session_secret.arn
        }       
        ]
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.prefix}app"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "shopbot"
        }
      }
      
      essential = true
    }
  ])
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.prefix}app"
  retention_in_days = 7
}

# ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "${var.prefix}service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.public_subnets
    security_groups = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }
}



