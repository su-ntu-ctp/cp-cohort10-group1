#!/bin/bash

AWS_REGION="ap-southeast-1"
ENV="dev"
LOG_GROUP="/ecs/shopmate-${ENV}"

# Get the latest log stream
echo "Finding latest log stream..."
LATEST_STREAM=$(aws logs describe-log-streams \
  --log-group-name $LOG_GROUP \
  --order-by LastEventTime \
  --descending \
  --limit 1 \
  --query "logStreams[0].logStreamName" \
  --output text \
  --region $AWS_REGION)

echo "Latest log stream: $LATEST_STREAM"

# Get the latest logs
echo "Fetching logs..."
aws logs get-log-events \
  --log-group-name $LOG_GROUP \
  --log-stream-name "$LATEST_STREAM" \
  --limit 50 \
  --query "events[*].{timestamp:timestamp,message:message}" \
  --output table \
  --region $AWS_REGION