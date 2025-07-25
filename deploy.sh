#!/bin/bash
set -e

# Configuration
ENV=${1:-dev}
AWS_REGION=${2:-ap-southeast-1}

# Validate environment
if [[ ! "$ENV" =~ ^(dev|uat|prod)$ ]]; then
  echo "❌ Error: Environment must be dev, uat, or prod"
  echo "Usage: ./deploy.sh [dev|uat|prod] [aws-region]"
  exit 1
fi

echo "🚀 Deploying ShopMate to $ENV environment in $AWS_REGION"

# Store original directory
ORIGINAL_DIR=$(pwd)
TERRAFORM_DIR="$ORIGINAL_DIR/terraform/environments/$ENV"

# Check if Terraform environment directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
  echo "❌ Error: Terraform environment directory not found: $TERRAFORM_DIR"
  exit 1
fi

# Navigate to Terraform environment
cd "$TERRAFORM_DIR"

# Initialize and apply Terraform
echo "📦 Initializing Terraform in $(pwd)..."
terraform init

echo "🏗️  Creating infrastructure..."
terraform apply -auto-approve

# Get ECR repository URL directly from AWS
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/shopmate"
echo "Using ECR repository: $ECR_REPO_URL"

# Build and push Docker image
echo "🐳 Building and pushing Docker image..."
cd "$ORIGINAL_DIR"

# Set default context and use default buildx builder
docker context use default
docker buildx use default
docker buildx build --platform=linux/amd64 --load -t shopmate:latest .

# ECR login and push
ECR_REGISTRY=$(echo $ECR_REPO_URL | cut -d'/' -f1)
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$ECR_REGISTRY"
docker tag shopmate:latest $ECR_REPO_URL:latest
docker push $ECR_REPO_URL:latest

# Force ECS service update
echo "🔄 Updating ECS service..."
CLUSTER_NAME="shopmate-$ENV"
SERVICE_NAME="shopmate-service-$ENV"
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment --region $AWS_REGION > /dev/null

echo ""
echo "✅ Deployment complete!"
echo "🌐 Application URL: https://shopmate.$ENV.sctp-sandbox.com"
echo "📊 Check AWS Console for monitoring and logs"
echo ""
echo "⏳ Note: It may take 2-3 minutes for the new deployment to be fully available."