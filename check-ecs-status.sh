#!/bin/bash

echo "Checking ECS service status..."
aws ecs describe-services --cluster shopmate-dev --services shopmate-service-dev --query "services[0].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount,Events:events[0:3].message}" --output json --region ap-southeast-1

echo -e "\nChecking ECS tasks..."
TASKS=$(aws ecs list-tasks --cluster shopmate-dev --query "taskArns" --output text --region ap-southeast-1)

if [ -z "$TASKS" ]; then
  echo "No tasks found"
else
  echo "Task details:"
  aws ecs describe-tasks --cluster shopmate-dev --tasks $TASKS --query "tasks[*].{Status:lastStatus,HealthStatus:healthStatus,Reason:stoppedReason}" --output table --region ap-southeast-1
  
  # Get container details for the first task
  TASK_ID=$(echo $TASKS | cut -d'/' -f3)
  echo -e "\nContainer details for task $TASK_ID:"
  aws ecs describe-tasks --cluster shopmate-dev --tasks $TASKS --query "tasks[0].containers[*].{Name:name,Status:lastStatus,Reason:reason}" --output table --region ap-southeast-1
  
  # Get log stream
  LOG_STREAM=$(aws ecs describe-tasks --cluster shopmate-dev --tasks $TASKS --query "tasks[0].containers[0].name" --output text --region ap-southeast-1)
  echo -e "\nLast 10 log entries:"
  aws logs get-log-events --log-group-name /ecs/shopmate-dev --log-stream-name "shopmate/$LOG_STREAM/$TASK_ID" --limit 10 --query "events[*].message" --output text --region ap-southeast-1 2>/dev/null || echo "No logs found"
fi