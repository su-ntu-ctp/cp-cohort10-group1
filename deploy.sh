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

# Initialize Terraform
echo "Initializing Terraform..."
cd terraform/environments/$ENV
terraform init

# Apply Terraform in stages to handle dependencies
echo "Stage 1: Creating network infrastructure..."
terraform apply -auto-approve \
  -target="module.shopmate.aws_vpc.main" \
  -target="module.shopmate.aws_subnet.public_a" \
  -target="module.shopmate.aws_subnet.public_b" \
  -target="module.shopmate.aws_internet_gateway.main" \
  -target="module.shopmate.aws_route_table.public" \
  -target="module.shopmate.aws_route_table_association.public_a" \
  -target="module.shopmate.aws_route_table_association.public_b" \
  -target="module.shopmate.aws_security_group.shopmate"

echo "Stage 2: Creating ECR repository..."
terraform apply -auto-approve -target="module.shopmate.aws_ecr_repository.shopmate"

# Get ECR repository URL from Terraform output
ECR_REPO_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || aws ecr describe-repositories --repository-names $ECR_REPO --query 'repositories[0].repositoryUri' --output text)

# Build and push Docker image
echo "Building and pushing Docker image..."
cd "$ORIGINAL_DIR"
docker buildx build --platform=linux/amd64 --load -t $ECR_REPO:$IMAGE_TAG .
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws ecr get-authorization-token --query 'authorizationData[].proxyEndpoint' --output text)

# Check if ECR_REPO_URL is not empty
if [ -z "$ECR_REPO_URL" ]; then
  echo "Error: ECR repository URL is empty. Cannot tag and push image."
  exit 1
fi

echo "Tagging image: $ECR_REPO:$IMAGE_TAG as $ECR_REPO_URL:$IMAGE_TAG"
docker tag "$ECR_REPO:$IMAGE_TAG" "$ECR_REPO_URL:$IMAGE_TAG"
docker push "$ECR_REPO_URL:$IMAGE_TAG"

# Return to Terraform directory
cd terraform/environments/$ENV

echo "Stage 3: Creating remaining infrastructure..."
terraform apply -auto-approve

echo ""
echo "Deployment complete!"
echo "Application URL can be found in the AWS Console under EC2 > Load Balancers"
echo "CloudWatch Dashboard can be found in the AWS Console under CloudWatch > Dashboards"
echo ""
echo "Note: It may take a few minutes for the ECS service to pull the new image and update the containers."