# ============================================================================
# INFRASTRUCTURE OUTPUTS
# ============================================================================
# # In shared/outputs.tf
# output "ecr_repository_url" {
#   value = aws_ecr_repository.shopbot.repository_url
# }


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


