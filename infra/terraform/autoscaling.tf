# ============================================================================
# AUTO SCALING CONFIGURATION
# ============================================================================

# ECS Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.app_count_max
  min_capacity       = var.app_count_min
  resource_id        = "service/${aws_ecs_cluster.shopbot.name}/${aws_ecs_service.shopbot.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based Auto Scaling Policy - Optimized for linear scaling
resource "aws_appautoscaling_policy" "cpu_scaling" {
  name               = "${var.prefix}-cpu-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0 # Lower target for faster scaling
    scale_out_cooldown = 120  # 2 minutes instead of 5
    scale_in_cooldown  = 180  # 3 minutes instead of 5
  }
}


# Memory-based Auto Scaling Policy
# Provides additional scaling trigger based on memory utilization
resource "aws_appautoscaling_policy" "memory_scaling" {
  name               = "${var.prefix}-memory-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 70.0 # Target memory utilization percentage
    scale_out_cooldown = 300  # Wait 5 minutes before scaling out again
    scale_in_cooldown  = 300  # Wait 5 minutes before scaling in again
  }
}