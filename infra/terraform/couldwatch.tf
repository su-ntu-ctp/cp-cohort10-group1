# ============================================================================
# CLOUDWATCH LOG GROUPS
# ============================================================================

# CloudWatch Log Group for main application logs
# Stores application logs with 7-day retention for cost optimization
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.prefix}app-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "${var.prefix}app-logs-${var.environment}"
    Environment = var.environment
    Service     = "ShopBot Application"
  }
}

# CloudWatch Log Group for Grafana monitoring service
# Longer retention for monitoring service logs
resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/${var.prefix}grafana-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.prefix}grafana-logs-${var.environment}"
    Environment = var.environment
    Service     = "Grafana Monitoring"
  }
}

# CloudWatch Log Group for Prometheus monitoring service
# Longer retention for monitoring service logs
resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/ecs/${var.prefix}prometheus-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.prefix}prometheus-logs-${var.environment}"
    Environment = var.environment
    Service     = "Prometheus Monitoring"
  }
}


# ============================================================================
# CLOUDWATCH DASHBOARD
# ============================================================================

# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "shopbot" {
  dashboard_name = "${var.prefix}dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.prefix}-service-${var.environment}", "ClusterName", aws_ecs_cluster.main.name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Resources"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "RunningTaskCount", "ServiceName", "${var.prefix}-service-${var.environment}", "ClusterName", aws_ecs_cluster.main.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Container Count"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix],
            [".", "TargetResponseTime", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Traffic & Response Time"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.orders.name],
            [".", "ConsumedWriteCapacityUnits", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Orders Database Activity"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          query  = "SOURCE '${aws_cloudwatch_log_group.app_logs.name}' | fields @timestamp, @message | filter @message like /order/ | sort @timestamp desc | limit 50"
          region = var.aws_region
          title  = "Order Activity Logs"
        }
      }
    ]
  })
}


