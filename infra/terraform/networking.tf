# ============================================================================
# NETWORKING
# ============================================================================

# VPC with public and private subnets
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "${var.prefix}-vpc-${var.environment}"
  cidr = "10.0.0.0/16"
  
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# ============================================================================
# SECURITY GROUPS
# ============================================================================

# ALB Security Group - allows HTTP/HTTPS from internet
resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb-sg-${var.environment}"
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

# App Security Group - allows traffic from ALB only
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.prefix}-ecs-tasks-sg-${var.environment}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================================================
# LOAD BALANCER
# ============================================================================

# Application Load Balancer
resource "aws_lb" "shopbot" {
  name               = "${var.prefix}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
}

# Target Group for ECS tasks
resource "aws_lb_target_group" "shopbot" {
  name        = "${var.prefix}-tg-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
}

# HTTPS Listener
resource "aws_lb_listener" "shopbot" {
  load_balancer_arn = aws_lb.shopbot.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.shopbot.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shopbot.arn
  }
}

# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "shopbot_http" {
  load_balancer_arn = aws_lb.shopbot.arn
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
