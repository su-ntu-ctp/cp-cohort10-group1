#!/bin/bash

# Environment-specific Grafana Dashboard Setup Script
# Creates separate dashboard files for each environment
# Usage: ./setup-dashboard-env.sh <environment> <cloudwatch_uid> <prometheus_uid>

ENV=$1
CLOUDWATCH_UID=$2
PROMETHEUS_UID=$3

if [ $# -ne 3 ]; then
    echo "Usage: $0 <environment> <cloudwatch_uid> <prometheus_uid>"
    echo "Examples:"
    echo "  $0 dev abc123 def456"
    echo "  $0 uat ghi789 jkl012"
    echo "  $0 prod mno345 pqr678"
    exit 1
fi

# Get environment-specific values from Terraform
CLUSTER_NAME=$(cd ../terraform && terraform workspace select $ENV && terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(cd ../terraform && terraform workspace select $ENV && terraform output -raw main_service_name)
REGION="ap-southeast-1"

echo "Setting up dashboard for $ENV environment:"
echo "  CloudWatch UID: $CLOUDWATCH_UID"
echo "  Prometheus UID: $PROMETHEUS_UID"
echo "  Cluster: $CLUSTER_NAME"
echo "  Service: $SERVICE_NAME"
echo ""

# Create environment-specific dashboard file
OUTPUT_FILE="shopbot-autoscaling-${ENV}.json"

# Copy base template and update with environment values
cp shopbot-autoscaling.json $OUTPUT_FILE

# Update with environment-specific values
sed -i '' \
    -e "s/eew5ojtt8xam8d/$CLOUDWATCH_UID/g" \
    -e "s/dew5ohkvbdhc0c/$PROMETHEUS_UID/g" \
    -e "s/shopmate-ecs-dev/$CLUSTER_NAME/g" \
    -e "s/shopmate-service-dev/$SERVICE_NAME/g" \
    -e "s/\"region\": \"default\"/\"region\": \"$REGION\"/g" \
    $OUTPUT_FILE

echo "✅ Dashboard created: $OUTPUT_FILE"
echo "📊 Import this file into Grafana at: https://shopmate.${ENV}.sctp-sandbox.com/grafana"
echo ""
echo "Next steps:"
echo "1. Access Grafana: https://shopmate.${ENV}.sctp-sandbox.com/grafana (admin/admin123)"
echo "2. Go to Dashboards → Import"
echo "3. Upload $OUTPUT_FILE"
echo "4. Dashboard will show $ENV environment metrics"