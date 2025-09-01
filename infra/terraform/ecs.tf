# ============================================================================
# CLOUDWATCH LOG GROUP FOR APPLICATION
# ============================================================================

# CloudWatch Log Group for main application logs
# Stores application logs with 7-day retention for cost optimization
resource "aws_cloudwatch_log_group" "shopbot" {
  name              = "/ecs/${var.prefix}-lg-${var.environment}"
  retention_in_days = 30
}

# ============================================================================
# ECS CLUSTER & SERVICES
# ============================================================================

# ECS Cluster
resource "aws_ecs_cluster" "shopbot" {
  name = "${var.prefix}-ecs-${var.environment}"
}

# ============================================================================
# ECS TASK DEFINITION - 3 ENVIRONMENT MAPPING
# ============================================================================

locals {
  # Map environments to image targets and tags
  image_config = {
    dev = {
      target = "development"
      tag    = "dev-latest"
      shell_access = true
    }
    staging = {
      target = "staging"
      tag    = "staging-latest"
      shell_access = true  # Limited shell via debug image
    }
    prod = {
      target = "production"
      tag    = "prod-latest"
      shell_access = false  # No shell access
    }
  }
  
  current_config = local.image_config[var.environment]
  image_uri = "${data.aws_ecr_repository.shopbot.repository_url}:${local.current_config.tag}"
}

resource "aws_ecs_task_definition" "shopbot" {
  family                   = "${var.prefix}-td-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.prefix}-container-${var.environment}"
      image = local.image_uri
      essential = true
      
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
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
        {
          name  = "SESSIONS_TABLE"
          value = aws_dynamodb_table.sessions.name
        }
      ]
      
      secrets = [
        {
          name      = "SESSION_SECRET"
          valueFrom = aws_secretsmanager_secret.session_secret.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.shopbot.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "${var.prefix}-logs-${var.environment}"
        }
      }
      
      # Health check only for dev (has curl)
      healthCheck = var.environment == "dev" ? {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      } : null
      
      # Security configurations
      readonlyRootFilesystem = var.environment == "prod"
      
      linuxParameters = {
        capabilities = {
          drop = ["ALL"]
          
        }
      }
    }
  ])
}

resource "aws_ecs_service" "shopbot" {
  name            = "${var.prefix}-service-${var.environment}"
  cluster         = aws_ecs_cluster.shopbot.id
  task_definition = aws_ecs_task_definition.shopbot.arn
  desired_count   = var.app_count_min
  launch_type     = "FARGATE"
  
  # Enable execute command based on shell access
  enable_execute_command = local.current_config.shell_access

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.shopbot.arn
    container_name   = "${var.prefix}-container-${var.environment}"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.shopbot]
  
  tags = {
    Environment = var.environment
    ImageTarget = local.current_config.target
    ShellAccess = local.current_config.shell_access ? "enabled" : "disabled"
  }
}
