#!/bin/bash
set -e

AWS_REGION="ap-southeast-1"
ECR_REPO="shopmate"
IMAGE_TAG="latest"
ENV="dev"

# Store original directory
ORIGINAL_DIR=$(pwd)

# Apply Terraform changes
echo "Applying Terraform changes..."
cd terraform/environments/$ENV
terraform init
terraform apply -auto-approve

# Get ECR repository URL
ECR_REPO_URL=$(aws ecr describe-repositories --repository-names $ECR_REPO --query 'repositories[0].repositoryUri' --output text --region $AWS_REGION)

echo "ECR Repository URL: $ECR_REPO_URL"

# Return to original directory
cd "$ORIGINAL_DIR"

# Build Docker image
echo "Building Docker image..."
docker buildx build --platform=linux/amd64 --load -t $ECR_REPO:$IMAGE_TAG .

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws ecr get-authorization-token --query 'authorizationData[].proxyEndpoint' --output text --region $AWS_REGION)

# Tag and push image
echo "Tagging and pushing image to ECR..."
docker tag $ECR_REPO:$IMAGE_TAG $ECR_REPO_URL:$IMAGE_TAG
docker push $ECR_REPO_URL:$IMAGE_TAG

echo "Restarting ECS service..."
aws ecs update-service --cluster shopmate-$ENV --service shopmate-service-$ENV --force-new-deployment --region $AWS_REGION

echo "Checking security group..."
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=shopmate-sg-$ENV" --query "SecurityGroups[0].GroupId" --output text --region $AWS_REGION)
echo "Security Group ID: $SG_ID"

echo "Adding port 80 rule if missing..."
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AWS_REGION || echo "Port 80 rule already exists"

echo "Adding port 443 rule if missing..."
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $AWS_REGION || echo "Port 443 rule already exists"

# Get application URL from Terraform output
cd terraform/environments/$ENV
APP_URL=$(terraform output -raw application_url 2>/dev/null || echo "https://shopmate.sctp-sandbox.com")

echo ""
echo "Deployment complete! The new version will be available in a few minutes."
echo "Application URL: $APP_URL"
echo ""
echo "Note: Certificate validation may take up to 30 minutes to complete."