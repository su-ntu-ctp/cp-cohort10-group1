variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "prefix" {
  description = "Resource prefix"
  type        = string
  default     = "shopbot-"
}


variable "environment" {
  description = "Environment name"
  type        = string
  }
  
variable "app_count" {
  description = "Number of docker containers to run"
  type        = number
  
}

variable "domain_name" {  
  description = "Domain name"
  type        = string
  }

variable "route53_zone_name" {
  description = "Route 53 zone name"
  type        = string
  default     = "sctp-sandbox.com"
}  
  
variable "create_route53_zone" {
  description = "Create Route 53 zone"
  type        = bool
  default     = false
}

variable "task_cpu" {
  description = "Task CPU"
  type        = string
}

variable "task_memory" {
  description = "Task memory"
  type = string
}

variable "max_capacity" {
  description = "Max scaling capacity"
  type        = number
}

variable "min_capacity" {
  description = "Max scaling capacity"
  type        = number
}