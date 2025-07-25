#!/bin/bash
set -e

# Configuration
ENV=${1:-dev}
AWS_REGION=${2:-ap-southeast-1}

# Validate environment
if [[ ! "$ENV" =~ ^(dev|uat|prod)$ ]]; then
  echo "❌ Error: Environment must be dev, uat, or prod"
  echo "Usage: ./destroy.sh [dev|uat|prod] [aws-region]"
  exit 1
fi

echo "🗑️  Destroying ShopMate resources in $ENV environment"

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

# Initialize Terraform
echo "📦 Initializing Terraform in $(pwd)..."
terraform init

# Clean up ECR images first (minimal AWS CLI usage)
echo "🧹 Cleaning up ECR images..."
ECR_REPO_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
if [ ! -z "$ECR_REPO_URL" ]; then
  REPO_NAME=$(echo $ECR_REPO_URL | cut -d'/' -f2)
  aws ecr batch-delete-image --repository-name $REPO_NAME --image-ids imageTag=latest --region $AWS_REGION 2>/dev/null || echo "No images to delete"
fi

# Destroy all resources with Terraform
echo "💥 Destroying infrastructure..."
terraform destroy -auto-approve

echo ""
echo "✅ Cleanup complete!"
echo "🔍 Verify in AWS Console that all resources have been removed"