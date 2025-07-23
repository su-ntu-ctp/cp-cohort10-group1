output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.shopmate.repository_url
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.shopmate.name
}

output "load_balancer_dns" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.shopmate.dns_name
}

output "application_url" {
  description = "The URL of the application"
  value       = "https://${var.domain_name}"
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch Dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.shopmate.dashboard_name}"
}

output "certificate_validation_instructions" {
  description = "Instructions for validating the certificate"
  value       = "Check the Route53 hosted zone for the validation records. If using an existing zone, you may need to add these records manually."
}

output "products_table_name" {
  description = "DynamoDB table name for products"
  value       = aws_dynamodb_table.products.name
}

output "orders_table_name" {
  description = "DynamoDB table name for orders"
  value       = aws_dynamodb_table.orders.name
}

output "carts_table_name" {
  description = "DynamoDB table name for carts"
  value       = aws_dynamodb_table.carts.name
}