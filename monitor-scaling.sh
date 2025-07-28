#!/bin/bash

# ShopMate Autoscaling Monitor Script
# Monitors ECS task count and CPU utilization in real-time

echo "=== ShopMate Autoscaling Monitor ==="
echo "Monitoring ECS service: shopmate-service-dev"
echo "Press Ctrl+C to stop monitoring"
echo ""

# Monitor task count changes
watch 'echo "=== Task Count ===" && aws ecs describe-services --cluster shopmate-dev --services shopmate-service-dev --query "services[0].{desired:desiredCount,running:runningCount}" --region ap-southeast-1 && echo "" && echo "=== Recent CPU Utilization ===" && aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=shopmate-service-dev Name=ClusterName,Value=shopmate-dev --start-time $(date -u -v-5M +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 60 --statistics Average --region ap-southeast-1 --query "Datapoints[-1].{Timestamp:Timestamp,CPU:Average}" 2>/dev/null || echo "No recent data"'