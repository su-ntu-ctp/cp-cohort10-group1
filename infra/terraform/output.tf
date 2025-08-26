# ============================================================================
# INFRASTRUCTURE OUTPUTS
# ============================================================================

# Container Registry Outputs
output "ecr_repository_url" {
  description = "Full ECR repository URL for pushing Docker images"
  value       = aws_ecr_repository.ecr_shopbot.repository_url
}

output "ecr_registry_url" {
  description = "ECR registry URL for Docker login authentication"
  value       = split("/", aws_ecr_repository.ecr_shopbot.repository_url)[0]
}

# Application Access URLs
output "app_url" {
  description = "Main application URL"
  value       = "https://${var.domain_name}"
}

output "prometheus_url" {
  description = "Prometheus monitoring dashboard URL"
  value       = "https://${var.domain_name}/prometheus"
}
  output "grafana_url" {
  description = "Grafana monitoring dashboard URL (admin/admin123)"
  value       = "https://${var.domain_name}/grafana"
}

# # Infrastructure Details
# output "load_balancer_dns" {
#   description = "Application Load Balancer DNS name"
#   value       = aws_lb.main.dns_name
# }

output "ecs_cluster_name" {
  description = "ECS cluster name for service management"
  value       = aws_ecs_cluster.main.name
}

# output "vpc_id" {
#   description = "VPC ID for network reference"
#   value       = module.vpc.vpc_id
# }


