#!/bin/bash
set -e

ENV=$1

if [ -z "$ENV" ]; then
    echo "Usage: $0 <environment>"
    echo "Available environments: dev, staging, prod"
    exit 1
fi

if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment '$ENV'"
    echo "Available environments: dev, staging, prod"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Deploying to $ENV environment..."
cd "$PROJECT_ROOT/infra/terraform/environments/$ENV"

terraform init
terraform plan -out=${ENV}.tfplan
terraform apply ${ENV}.tfplan

echo "✅ $ENV deployment completed!"
