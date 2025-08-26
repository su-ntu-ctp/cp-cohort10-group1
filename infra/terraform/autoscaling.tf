# ============================================================================
# AUTO SCALING CONFIGURATION
# ============================================================================

# ECS Auto Scaling Target
# Defines the scalable resource (ECS service) and its capacity limits
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"  # Scale the number of running tasks
  service_namespace  = "ecs"

  tags = {
    Name        = "${var.prefix}autoscaling-target-${var.environment}"
    Environment = var.environment
  }
}

# CPU-based Auto Scaling Policy
# Scales out when average CPU utilization exceeds 70%
resource "aws_appautoscaling_policy" "cpu_scaling" {
  name               = "${var.prefix}cpu-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0  # Target CPU utilization percentage
    scale_out_cooldown = 300   # Wait 5 minutes before scaling out again
    scale_in_cooldown  = 300   # Wait 5 minutes before scaling in again
  }
}

# Memory-based Auto Scaling Policy
# Provides additional scaling trigger based on memory utilization
resource "aws_appautoscaling_policy" "memory_scaling" {
  name               = "${var.prefix}memory-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 70.0  # Target memory utilization percentage
    scale_out_cooldown = 300   # Wait 5 minutes before scaling out again
    scale_in_cooldown  = 300   # Wait 5 minutes before scaling in again
  }
}