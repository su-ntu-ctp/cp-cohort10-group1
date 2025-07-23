#!/bin/bash
set -e

# Configuration
AWS_REGION=${1:-ap-southeast-1}
ENV=${2:-dev}
ECR_REPO="shopmate"
IMAGE_TAG="latest"

# Get ECR repository URL
ECR_REPO_URL=$(aws ecr describe-repositories --repository-names $ECR_REPO --query 'repositories[0].repositoryUri' --output text)

echo "ECR Repository URL: $ECR_REPO_URL"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL

# Create and use a new builder instance with multi-architecture support
echo "Setting up Docker buildx..."
docker buildx create --name multiarch-builder --use || docker buildx use multiarch-builder
docker buildx inspect --bootstrap

# Build and push multi-architecture image directly to ECR
echo "Building and pushing multi-architecture image..."
docker buildx build --platform linux/amd64,linux/arm64 \
  --tag $ECR_REPO_URL:$IMAGE_TAG \
  --push \
  .

echo "Multi-architecture image built and pushed successfully!"
echo "Image: $ECR_REPO_URL:$IMAGE_TAG"

# Update ECS service to use the new image
echo "Updating ECS service..."
aws ecs update-service --cluster shopmate-$ENV --service shopmate-service-$ENV --force-new-deployment --region $AWS_REGION

echo "Deployment update initiated. The new version will be available in a few minutes."
echo "You can check the status in the AWS ECS console."