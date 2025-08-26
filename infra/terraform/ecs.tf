# ============================================================================
# ECS CLUSTER & SERVICES
# ============================================================================

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.prefix}ecs-${var.environment}"
}

# ECS Task Definition

resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.prefix}app-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.task_cpu}"
  memory                   = "${var.task_memory}"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.prefix}container-${var.environment}"
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
          "awslogs-group"         = "/ecs/${var.prefix}app-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "${var.prefix}"
        }
      }
      
      essential = true
    }
  ])
}


# ECS Service for main application
resource "aws_ecs_service" "app_service" {
  name            = "${var.prefix}service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.prefix}container-${var.environment}"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.https]
}