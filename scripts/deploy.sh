#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../infra/terraform"
ENVIRONMENT=${1:-dev}

log() { echo -e "\033[0;34m[$(date '+%H:%M:%S')]\033[0m $1"; }
success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }

[[ "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]] || { echo "Usage: $0 [dev|staging|prod]"; exit 1; }

# Deploy shared resources
log "Deploying shared resources..."
cd "$TERRAFORM_DIR/shared"
[ ! -d ".terraform" ] && terraform init
terraform apply -auto-approve
success "Shared resources deployed"

# Deploy environment
log "Deploying $ENVIRONMENT environment..."
cd "$TERRAFORM_DIR/environments/$ENVIRONMENT"
[ ! -d ".terraform" ] && terraform init
terraform apply -auto-approve
success "$ENVIRONMENT environment deployed"

# Show outputs
echo
log "=== DEPLOYMENT OUTPUTS ==="
terraform output

success "Deployment completed for $ENVIRONMENT"
