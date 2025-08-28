# ============================================================================
# TERRAFORM OUTPUTS
# ============================================================================
# Output values used by deployment scripts and for reference

output "ecr_repository_url" {
  description = "ECR repository URL for Docker image storage"
  value       = data.aws_ecr_repository.shopbot.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name for service deployment"
  value       = aws_ecs_cluster.shopbot.name
}

output "application_url" {
  description = "Application URL with HTTPS"
  value       = "https://${var.domain_name}"
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL for monitoring"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.prefix}-dashboard-${var.environment}"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "https://${var.domain_name}/grafana"
}

output "prometheus_url" {
  description = "Prometheus metrics URL"
  value       = "https://${var.domain_name}/prometheus"
}

output "grafana_datasource_setup" {
  description = "Commands to setup Grafana data sources and get UIDs"
  value       = <<-EOT
# After deployment, setup Grafana data sources:
# 1. Access Grafana: https://${var.domain_name}/grafana (admin/admin123)
# 2. Add CloudWatch data source (get UID from URL)
# 3. Add Prometheus data source: https://${var.domain_name}/prometheus (get UID from URL)
# 4. Run: ./update-dashboard.sh <cloudwatch_uid> <prometheus_uid> ${aws_ecs_cluster.shopbot.name} ${aws_ecs_service.shopbot.name} ${var.aws_region}
EOT
}

output "main_service_name" {
  description = "Main application ECS service name"
  value       = aws_ecs_service.shopbot.name
}

output "prometheus_service_name" {
  description = "Prometheus ECS service name"
  value       = aws_ecs_service.prometheus.name
}

output "grafana_service_name" {
  description = "Grafana ECS service name"
  value       = aws_ecs_service.grafana.name
}
