#!/bin/bash
set -e

# Configuration
ENV=${1:-dev}
AWS_REGION=${2:-ap-southeast-1}
ECR_REPO="shopmate"

echo "Destroying ShopMate resources in $ENV environment in $AWS_REGION"

# Delete all images from ECR repository
echo "Deleting images from ECR repository..."
IMAGES=$(aws ecr list-images --repository-name $ECR_REPO --region $AWS_REGION --query 'imageIds[*]' --output json 2>/dev/null || echo "[]")
if [ "$IMAGES" != "[]" ]; then
  aws ecr batch-delete-image --repository-name $ECR_REPO --image-ids "$IMAGES" --region $AWS_REGION || echo "No images to delete"
fi

# Destroy Terraform resources
echo "Destroying Terraform resources..."
cd terraform/environments/$ENV
terraform init

# First destroy the certificate validation resources
echo "First destroying certificate validation resources..."
terraform destroy -auto-approve -target="module.shopmate.aws_route53_record.cert_validation" || echo "Certificate validation records may already be gone"
terraform destroy -auto-approve -target="module.shopmate.aws_acm_certificate_validation.shopmate" || echo "Certificate validation may already be gone"

# Then destroy the ACM certificate
echo "Destroying ACM certificate..."
terraform destroy -auto-approve -target="module.shopmate.aws_acm_certificate.shopmate" || echo "Certificate may already be gone"

# Then destroy the ECS service if it exists
echo "Destroying ECS service if it exists..."
terraform destroy -auto-approve -target="module.shopmate.aws_ecs_service.shopmate" || echo "ECS service may not exist or already be gone"

# Finally destroy everything else
echo "Destroying remaining resources..."
terraform destroy -auto-approve

# Delete ECR repository
echo "Deleting ECR repository..."
aws ecr delete-repository --repository-name $ECR_REPO --force --region $AWS_REGION || echo "ECR repository not found or already deleted"

echo "Cleanup complete!"