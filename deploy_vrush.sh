#!/bin/bash
set -e

# Configuration
ECR_REPO="255945442255.dkr.ecr.ap-southeast-1.amazonaws.com/shopbot"
REGION="ap-southeast-1"
CLUSTER="shopbot-ecs-dev"

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO

echo "🏗️ Building application image..."
cd app
docker buildx build --platform linux/amd64 -t shopbot-app . --load
cd ..

echo "🏗️ Building Prometheus image..."
docker buildx build --platform linux/amd64 -f infra/Dockerfile.prometheus -t shopbot-prometheus . --load

echo "📤 Pushing images to ECR..."
docker tag shopbot-app:latest $ECR_REPO:latest
docker tag shopbot-prometheus:latest $ECR_REPO:prometheus

docker push $ECR_REPO:latest
docker push $ECR_REPO:prometheus

echo "🚀 Deploying services..."
aws ecs update-service --cluster $CLUSTER --service shopbot-service-dev --force-new-deployment --region $REGION
aws ecs update-service --cluster $CLUSTER --service shopbot-prometheus-dev --force-new-deployment --region $REGION

echo "✅ Deployment complete! Check:"
echo "   App: https://dev-shopbot.sctp-sandbox.com"
echo "   Metrics: https://dev-shopbot.sctp-sandbox.com/prometheus"