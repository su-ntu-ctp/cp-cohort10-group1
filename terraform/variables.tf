variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "The environment (dev, uat, prod)"
  type        = string
  default     = "dev"
}

variable "app_count" {
  description = "Number of instances of the task to run"
  type        = number
  default     = 1
}

variable "session_secret" {
  description = "Secret for session management"
  type        = string
  default     = "shopmate-default-secret"
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "shopmate-app.example.com"
}

variable "route53_zone_name" {
  description = "Route53 zone name (e.g., example.com)"
  type        = string
  default     = "example.com"
}

variable "create_route53_zone" {
  description = "Whether to create a new Route53 zone or use an existing one"
  type        = bool
  default     = false
}