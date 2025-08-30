variable "aws_region" {
  description = "The AWS region where all resources will be deployed"
  type        = string
  default     = "ap-southeast-1"
}

variable "prefix" {
  description = "Resource prefix"
  type        = string
  default     = "shopbot"
}


variable "environment" {
  description = "The deployment environment (dev, staging, prod). This affects resource naming and scaling parameters. Must be explicitly specified."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
  
variable "domain_name" {
  description = "Fully qualified domain name for the application (e.g., shopbot.example.com). SSL certificate will be issued for this domain."
  type        = string
}

variable "route53_zone_name" {
  description = "The Route53 hosted zone name (e.g., example.com). Must be the parent domain of the application domain."
  type        = string
  default     = "sctp-sandbox.com"
}

variable "create_route53_zone" {
  description = "Whether to create a new Route53 hosted zone (true) or use an existing one (false). Set to false if you already have a hosted zone for your domain."
  type        = bool
  default     = false
}

variable "task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, etc.)"
  type        = string
}

variable "task_memory" {
  description = "Memory for ECS task in MB (512, 1024, 2048, etc.)"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy. Use commit SHA for immutable deployments or environment-specific tags."
  type        = string
}

variable "app_count_min" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
}

variable "app_count_max" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
}