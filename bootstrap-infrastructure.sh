#!/bin/bash
# Bootstrap shared infrastructure including OIDC role for ShopBot

echo "🔐 Creating Parameter Store backend configurations first..."

# Main terraform backend config (for environment workspaces)
aws ssm put-parameter \
  --name "/terraform/backend/shopbot" \
  --value 'bucket = "sctp-ce10-tfstate"
key    = "shopbot/env/terraform.tfstate"
region = "ap-southeast-1"
dynamodb_table = "shopbot-terraform-locks"
encrypt = true' \
  --type "SecureString" \
  --overwrite

# Shared terraform backend config (for shared infrastructure)
aws ssm put-parameter \
  --name "/terraform/backend/shared" \
  --value 'bucket = "sctp-ce10-tfstate"
key    = "shopbot/shared/terraform.tfstate"
region = "ap-southeast-1"
dynamodb_table = "shopbot-terraform-locks"
encrypt = true' \
  --type "SecureString" \
  --overwrite

echo "✅ Parameter Store backend configurations created!"
echo "🔐 Now deploying shared infrastructure (ECR + OIDC + State Locking)..."

# Deploy all shared infrastructure
cd infra/terraform/shared

# Get backend configuration for shared infrastructure
aws ssm get-parameter \
  --name "/terraform/backend/shared" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text > backend.hcl

terraform init -reconfigure -backend-config=backend.hcl

# Check if OIDC role exists and import if needed
if aws iam get-role --role-name shopbot-github-actions-role >/dev/null 2>&1; then
  echo "⚠️ OIDC role exists, importing to Terraform state"
  terraform import aws_iam_role.github_actions shopbot-github-actions-role || true
  terraform import aws_iam_role_policy.github_actions_ecr shopbot-github-actions-role:shopbot-github-actions-ecr-policy || true
fi

# Check if DynamoDB table exists, disable locking if it doesn't
if aws dynamodb describe-table --table-name shopbot-terraform-locks >/dev/null 2>&1; then
  echo "✅ DynamoDB table exists, using state locking"
  terraform apply -auto-approve
else
  echo "⚠️ DynamoDB table doesn't exist, disabling locking for initial deployment"
  terraform apply -auto-approve -lock=false
fi

# Get the role ARN
ROLE_ARN=$(terraform output -raw github_actions_role_arn)
echo ""
echo "✅ Shared infrastructure deployed!"
echo "📋 Add this to GitHub secrets as AWS_GITHUB_ACTIONS_ROLE_ARN:"
echo "$ROLE_ARN"
echo ""
echo "After adding the secret, workflows will use OIDC authentication."