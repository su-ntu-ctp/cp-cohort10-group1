output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.ecr_shopbot.repository_url
}

output "ecr_registry_url" {
  description = "ECR registry URL for docker login"
  value       = split("/", aws_ecr_repository.ecr_shopbot.repository_url)[0]
}

output "app_url" {
  value = "https://${var.domain_name}"
}

output "prometheus_url" {
  value = "https://${var.domain_name}/prometheus"
}

output "grafana_url" {
  value = "https://${var.domain_name}/grafana"
}
