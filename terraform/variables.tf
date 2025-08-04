variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "prefix" {
  description = "Resource prefix"
  type        = string
  default     = "shopbot"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
  
variable "app_count" {
  description = "Number of docker containers to run"
  type        = number
  default     = 1 
}

variable "domain_name" {  
  description = "Domain name"
  type        = string
  default     = "shopbot.sctp-sandbox.com"
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