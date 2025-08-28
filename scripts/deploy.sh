#!/bin/bash

# Terraform Deployment Script for ShopBot Infrastructure
# Supports shared resources and environment-specific deployments

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../infra/terraform"
ENVIRONMENT=${1:-dev}
ACTION=${2:-apply}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Validate inputs
validate_inputs() {
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        error "Invalid environment. Use: dev, staging, or prod"
    fi
    
    if [[ ! "$ACTION" =~ ^(plan|apply|destroy|output)$ ]]; then
        error "Invalid action. Use: plan, apply, destroy, or output"
    fi
}

# Deploy shared resources
deploy_shared() {
    log "Deploying shared resources..."
    
    cd "$TERRAFORM_DIR/shared"
    
    if [ ! -f ".terraform/terraform.tfstate" ]; then
        log "Initializing shared Terraform..."
        terraform init
    fi
    
    case $ACTION in
        "plan")
            terraform plan
            ;;
        "apply")
            terraform plan
            read -p "Apply shared resources? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                terraform apply -auto-approve
                success "Shared resources deployed"
            else
                warning "Shared deployment cancelled"
            fi
            ;;
        "destroy")
            warning "Destroying shared resources will affect ALL environments!"
            read -p "Are you sure? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                terraform destroy -auto-approve
                success "Shared resources destroyed"
            else
                warning "Shared destruction cancelled"
            fi
            ;;
        "output")
            terraform output
            ;;
    esac
}

# Deploy environment-specific resources
deploy_environment() {
    log "Deploying $ENVIRONMENT environment..."
    
    cd "$TERRAFORM_DIR/environments/$ENVIRONMENT"
    
    if [ ! -f ".terraform/terraform.tfstate" ]; then
        log "Initializing $ENVIRONMENT Terraform..."
        terraform init
    fi
    
    case $ACTION in
        "plan")
            terraform plan -var-file="../$ENVIRONMENT.tfvars"
            ;;
        "apply")
            terraform plan -var-file="../$ENVIRONMENT.tfvars"
            read -p "Apply $ENVIRONMENT environment? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                terraform apply -var-file="../$ENVIRONMENT.tfvars" -auto-approve
                success "$ENVIRONMENT environment deployed"
                
                # Show outputs after successful deployment
                log "Deployment outputs:"
                terraform output
            else
                warning "$ENVIRONMENT deployment cancelled"
            fi
            ;;
        "destroy")
            warning "This will destroy the $ENVIRONMENT environment!"
            read -p "Are you sure? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                terraform destroy -var-file="../$ENVIRONMENT.tfvars" -auto-approve
                success "$ENVIRONMENT environment destroyed"
            else
                warning "$ENVIRONMENT destruction cancelled"
            fi
            ;;
        "output")
            terraform output
            ;;
    esac
}

# Show all outputs
show_all_outputs() {
    log "=== SHARED RESOURCES OUTPUTS ==="
    cd "$TERRAFORM_DIR/shared"
    terraform output 2>/dev/null || echo "No shared outputs available"
    
    echo
    log "=== $ENVIRONMENT ENVIRONMENT OUTPUTS ==="
    cd "$TERRAFORM_DIR/environments/$ENVIRONMENT"
    terraform output 2>/dev/null || echo "No environment outputs available"
}

# Main execution
main() {
    validate_inputs
    
    log "Starting Terraform deployment"
    log "Environment: $ENVIRONMENT"
    log "Action: $ACTION"
    
    case $ACTION in
        "output")
            show_all_outputs
            ;;
        *)
            # Deploy shared resources first (except for destroy)
            if [ "$ACTION" != "destroy" ]; then
                deploy_shared
                echo
            fi
            
            # Deploy environment-specific resources
            deploy_environment
            
            # If destroying, clean up shared resources last
            if [ "$ACTION" == "destroy" ]; then
                echo
                deploy_shared
            fi
            ;;
    esac
    
    success "Terraform $ACTION completed for $ENVIRONMENT"
}

# Usage information
usage() {
    echo "Usage: $0 [ENVIRONMENT] [ACTION]"
    echo
    echo "ENVIRONMENT:"
    echo "  dev      Deploy to development environment (default)"
    echo "  staging  Deploy to staging environment"
    echo "  prod     Deploy to production environment"
    echo
    echo "ACTION:"
    echo "  plan     Show deployment plan (default)"
    echo "  apply    Deploy infrastructure"
    echo "  destroy  Destroy infrastructure"
    echo "  output   Show deployment outputs"
    echo
    echo "Examples:"
    echo "  $0 dev plan          # Plan dev deployment"
    echo "  $0 prod apply        # Deploy to production"
    echo "  $0 staging output    # Show staging outputs"
    echo "  $0 dev destroy       # Destroy dev environment"
}

# Handle help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main
