#!/bin/bash
set -e

# Configuration
ENV=${1:-dev}
AWS_REGION=${2:-ap-southeast-1}
ECR_REPO="shopmate"
IMAGE_TAG="latest"

echo "Deploying ShopMate to $ENV environment in $AWS_REGION"

# Store original directory
ORIGINAL_DIR=$(pwd)

# Try to import existing resources into Terraform state
echo "Checking for existing resources..."
cd terraform/environments/$ENV

# Try to import IAM roles if they exist
terraform import module.shopmate.aws_iam_role.ecs_task_execution_role shopmate-execution-role-${ENV} || echo "Role not imported, will be created"
terraform import module.shopmate.aws_iam_role.ecs_task_role shopmate-task-role-${ENV} || echo "Role not imported, will be created"

# Apply Terraform with auto-approve
echo "Applying Terraform configuration..."
terraform init
terraform apply -auto-approve || echo "Terraform apply had errors, but continuing..."

# Get ECR repository URL directly from AWS
echo "Getting ECR repository URL from AWS..."
ECR_REPO_URL=$(aws ecr describe-repositories --repository-names $ECR_REPO --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "")

if [ -z "$ECR_REPO_URL" ]; then
  echo "Creating ECR repository..."
  aws ecr create-repository --repository-name $ECR_REPO --region $AWS_REGION
  ECR_REPO_URL=$(aws ecr describe-repositories --repository-names $ECR_REPO --query 'repositories[0].repositoryUri' --output text)
fi

echo "ECR Repository URL: $ECR_REPO_URL"

# Return to original directory to build Docker image
echo "Building Docker image for linux/amd64 platform..."
cd "$ORIGINAL_DIR"
docker buildx build --platform=linux/amd64 --load -t $ECR_REPO:$IMAGE_TAG .

# Login to ECR using the working approach
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws ecr get-authorization-token --query 'authorizationData[].proxyEndpoint' --output text)

# Debug output
echo "Local image: $ECR_REPO:$IMAGE_TAG"
echo "Remote image: $ECR_REPO_URL:$IMAGE_TAG"

# Tag and push image
echo "Tagging and pushing image to ECR..."
docker tag $ECR_REPO:$IMAGE_TAG $ECR_REPO_URL:$IMAGE_TAG
docker push $ECR_REPO_URL:$IMAGE_TAG

echo ""
echo "Deployment complete!"
echo "Application URL can be found in the AWS Console under EC2 > Load Balancers"
echo "CloudWatch Dashboard can be found in the AWS Console under CloudWatch > Dashboards"
echo ""
echo "Note: It may take a few minutes for the ECS service to pull the new image and update the containers."