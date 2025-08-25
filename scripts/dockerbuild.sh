#!/bin/bash
set -e

AWS_REGION="ap-southeast-1"
ECR_REPO="shopbot-ecr"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🐳 Building and pushing Docker images..."

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

# Build and push main app image
echo "🔨 Building main app image..."
cd "$PROJECT_ROOT/app"
docker build -t $ECR_REPO:latest .
docker tag $ECR_REPO:latest $ECR_URI:latest
docker push $ECR_URI:latest

# Build and push Prometheus image
echo "🔨 Building Prometheus image..."
cd "$PROJECT_ROOT"
docker build -f infra/Dockerfile.prometheus -t $ECR_REPO:prometheus .
docker tag $ECR_REPO:prometheus $ECR_URI:prometheus
docker push $ECR_URI:prometheus

echo "✅ All Docker images pushed successfully!"
echo "App image: $ECR_URI:latest"
echo "Prometheus image: $ECR_URI:prometheus"
