#!/bin/bash
set -e

echo "🗑️  Starting infrastructure destruction..."
echo "⚠️  This will destroy ALL resources including shared ECR repository!"
echo "⚠️  All Docker images will be permanently deleted!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Destruction cancelled"
    exit 1
fi

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "🗑️  Step 1: Destroying dev environment..."
cd "$SCRIPT_DIR/infra/terraform/environments/dev"
if [ -f "terraform.tfstate" ] || [ -d ".terraform" ]; then
    terraform destroy -auto-approve
    echo "✅ Dev environment destroyed"
else
    echo "ℹ️  No dev environment state found, skipping..."
fi

echo ""
echo "🗑️  Step 2: Force deleting ECR repository with all images..."
echo "🗑️  Deleting all images in shopbot repository..."
aws ecr list-images --repository-name shopbot --region ap-southeast-1 --query 'imageIds[*]' --output json > /tmp/images.json 2>/dev/null || echo "ℹ️  Repository may not exist or is empty"
if [ -s /tmp/images.json ] && [ "$(cat /tmp/images.json)" != "[]" ]; then
    aws ecr batch-delete-image --repository-name shopbot --region ap-southeast-1 --image-ids file:///tmp/images.json
    echo "✅ All images deleted from ECR repository"
else
    echo "ℹ️  No images found in repository"
fi
rm -f /tmp/images.json

echo ""
echo "🗑️  Step 3: Destroying shared resources (ECR repository)..."
cd "$SCRIPT_DIR/infra/terraform/shared"
if [ -f "terraform.tfstate" ] || [ -d ".terraform" ]; then
    terraform destroy -auto-approve
    echo "✅ Shared resources destroyed"
else
    echo "ℹ️  No shared resources state found, skipping..."
fi

echo ""
echo "🧹 Step 4: Cleaning up local files..."
cd "$SCRIPT_DIR"

# Remove terraform state files and directories
find . -name "terraform.tfstate*" -delete
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".terraform.lock.hcl" -delete

echo "✅ Local terraform files cleaned up"

echo ""
echo "🎉 All resources destroyed successfully!"
echo "💡 You can now safely delete this repository if needed"