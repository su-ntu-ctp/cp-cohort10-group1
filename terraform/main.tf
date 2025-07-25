provider "aws" {
  region = var.aws_region
}

# ACM Certificate
resource "aws_acm_certificate" "shopmate" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "shopmate-cert-${var.environment}"
  }
}

# Certificate Validation
resource "aws_acm_certificate_validation" "shopmate" {
  certificate_arn         = aws_acm_certificate.shopmate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route53 Zone (use existing zone if available)
data "aws_route53_zone" "selected" {
  count = var.create_route53_zone ? 0 : 1
  name  = var.route53_zone_name
}

resource "aws_route53_zone" "primary" {
  count = var.create_route53_zone ? 1 : 0
  name  = var.route53_zone_name
}

locals {
  route53_zone_id = var.create_route53_zone ? aws_route53_zone.primary[0].zone_id : data.aws_route53_zone.selected[0].zone_id
}

# Certificate validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.shopmate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.route53_zone_id
}

# DNS record for the application
resource "aws_route53_record" "shopmate" {
  zone_id = local.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.shopmate.dns_name
    zone_id                = aws_lb.shopmate.zone_id
    evaluate_target_health = true
  }
}

# ECR Repository
resource "aws_ecr_repository" "shopmate" {
  name                 = "shopmate"
  image_tag_mutability = "MUTABLE"
}

# ECS Cluster
resource "aws_ecs_cluster" "shopmate" {
  name = "shopmate-${var.environment}"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "shopmate" {
  name = "/ecs/shopmate-${var.environment}"
  retention_in_days = 30
}

# DynamoDB Tables
resource "aws_dynamodb_table" "products" {
  name           = "shopmate-products-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "N"
  }
}

resource "aws_dynamodb_table" "orders" {
  name           = "shopmate-orders-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "N"
  }
}

resource "aws_dynamodb_table" "carts" {
  name           = "shopmate-carts-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"
  
  attribute {
    name = "userId"
    type = "S"
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "shopmate-execution-role-${var.environment}"

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

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Role for DynamoDB Access
resource "aws_iam_role" "ecs_task_role" {
  name = "shopmate-task-role-${var.environment}"

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

resource "aws_iam_policy" "dynamodb_access" {
  name        = "shopmate-dynamodb-access-${var.environment}"
  description = "Allow access to DynamoDB tables"

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
          "dynamodb:DeleteItem"
        ]
        Effect = "Allow"
        Resource = [
          aws_dynamodb_table.products.arn,
          aws_dynamodb_table.orders.arn,
          aws_dynamodb_table.carts.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_dynamodb" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "shopmate-vpc-${var.environment}"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "shopmate-public-a-${var.environment}"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "shopmate-public-b-${var.environment}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "shopmate-igw-${var.environment}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "shopmate-public-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "shopmate" {
  name        = "shopmate-sg-${var.environment}"
  description = "Allow inbound traffic to ShopMate"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# ECS Task Definition
resource "aws_ecs_task_definition" "shopmate" {
  family                   = "shopmate-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "shopmate"
      image     = "${aws_ecr_repository.shopmate.repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
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
          name  = "SESSION_SECRET"
          value = var.session_secret
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
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.shopmate.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "shopmate"
        }
      }
    }
  ])
}

# Load Balancer
resource "aws_lb" "shopmate" {
  name               = "shopmate-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.shopmate.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "shopmate" {
  name        = "shopmate-tg-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "shopmate" {
  load_balancer_arn = aws_lb.shopmate.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.shopmate.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shopmate.arn
  }
}

resource "aws_lb_listener" "shopmate_http" {
  load_balancer_arn = aws_lb.shopmate.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ECS Service
resource "aws_ecs_service" "shopmate" {
  name            = "shopmate-service-${var.environment}"
  cluster         = aws_ecs_cluster.shopmate.id
  task_definition = aws_ecs_task_definition.shopmate.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.shopmate.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.shopmate.arn
    container_name   = "shopmate"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.shopmate]
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "shopmate" {
  dashboard_name = "shopmate-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.shopmate.name, "ClusterName", aws_ecs_cluster.shopmate.name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS CPU & Memory Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.shopmate.arn_suffix],
            [".", "TargetResponseTime", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Load Balancer Metrics"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.shopmate.name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Application Logs"
        }
      }
    ]
  })
}