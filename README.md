# ShopBot E-commerce Application

Contributors - Vrushali Bavare and Ramya Rajendran.
Group 1 - NTU SCTP Cohort 10

A simple e-commerce application built with Node.js and Express, designed to be easily containerized and deployed to AWS ECS Fargate.

# ShopBot E-commerce Infrastructure

This Terraform configuration deploys a complete e-commerce application infrastructure on AWS using modern cloud-native services.

## Architecture Overview

```
Internet → ALB → ECS Fargate → DynamoDB
                    ↓
              CloudWatch Logs
                    ↓
            Prometheus & Grafana
```

## Infrastructure Components

### Core Services
- **ECS Fargate**: Containerized application hosting
- **Application Load Balancer**: HTTPS traffic distribution
- **DynamoDB**: NoSQL database for application data
- **ECR**: Container image registry
- **Route 53**: DNS management
- **ACM**: SSL certificate management

### Monitoring Stack
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **CloudWatch**: AWS native monitoring and logging

### Security & Networking
- **VPC**: Isolated network environment
- **Security Groups**: Network access control
- **IAM Roles**: Service permissions
- **Secrets Manager**: Secure credential storage

## File Structure

```
terraform/
├── main.tf              # Provider configuration
├── variables.tf         # Input variables with validation
├── output.tf           # Infrastructure outputs
├── networking.tf       # VPC, ALB, security groups
├── ecs.tf             # ECS cluster and services
├── iam.tf             # IAM roles and policies
├── storage.tf         # ECR and DynamoDB tables
├── dns.tf             # Route 53 and SSL certificates
├── autoscaling.tf     # Auto scaling configuration
├── monitoring.tf      # Prometheus and Grafana
├── couldwatch.tf      # CloudWatch logs and dashboard
└── environments/      # Environment-specific configurations
    ├── dev/
    ├── staging/
    └── prod/
```

## Environment Configuration

Each environment has its own configuration:

### Development
- **Domain**: `dev-shopbot.sctp-sandbox.com`
- **Resources**: 1 task, 256 CPU, 512 MB memory
- **Scaling**: 1-3 tasks

### Staging
- **Domain**: `staging-shopbot.sctp-sandbox.com`
- **Resources**: 2 tasks, 512 CPU, 1024 MB memory
- **Scaling**: 1-5 tasks

### Production
- **Domain**: `shopbot.sctp-sandbox.com`
- **Resources**: 3 tasks, 1024 CPU, 2048 MB memory
- **Scaling**: 1-10 tasks

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.3.0
3. **Docker** for building container images
4. **S3 bucket** for Terraform state storage

## Deployment Instructions

### 1. Build and Push Docker Images

```bash
# Build and push application image
./scripts/dockerbuild.sh

# This builds both:
# - shopbot-ecr:latest (main application)
# - shopbot-ecr:prometheus (monitoring)
```



### 3. Access Applications

After deployment, access your services:

- **Main App**: `https://{environment}-shopbot.sctp-sandbox.com`
- **Prometheus**: `https://{environment}-shopbot.sctp-sandbox.com/prometheus`
- **Grafana**: `https://{environment}-shopbot.sctp-sandbox.com/grafana`
  - Username: `admin`
  - Password: `admin123`

## Monitoring Setup

### Prometheus Configuration
- Scrapes application metrics from `/metrics` endpoint
- Configured in `prometheus.yml`
- Accessible at `/prometheus` path

### Grafana Dashboards
1. Add Prometheus data source: `https://{domain}/prometheus`
2. Import dashboard ID `1860` for Node.js metrics
3. Create custom dashboards for business metrics

### CloudWatch Dashboard
- ECS resource utilization
- Load balancer metrics
- DynamoDB activity
- Application logs

## Auto Scaling

The infrastructure includes automatic scaling based on:
- **CPU Utilization**: Scales when average CPU > 70%
- **Memory Utilization**: Scales when average memory > 70%
- **Cooldown Period**: 5 minutes between scaling events

## Security Features

- **Network Isolation**: Private subnets for application containers
- **Security Groups**: Restrictive ingress/egress rules
- **IAM Roles**: Least privilege access
- **Secrets Management**: Encrypted credential storage
- **HTTPS Only**: SSL termination at load balancer

## Cost Optimization

- **Fargate Spot**: Consider for non-production environments
- **DynamoDB On-Demand**: Pay per request pricing
- **Log Retention**: 7 days for app logs, 30 days for monitoring
- **ECR Lifecycle**: Automatic cleanup of old images

## Troubleshooting

### Common Issues

1. **Container Won't Start**
   ```bash
   aws ecs describe-services --cluster shopbot-ecs-{env} --services shopbot-service-{env}
   aws logs describe-log-streams --log-group-name /ecs/shopbot-app-{env}
   ```

2. **SSL Certificate Issues**
   ```bash
   aws acm list-certificates --region ap-southeast-1
   aws route53 list-resource-record-sets --hosted-zone-id {zone-id}
   ```

3. **Load Balancer Health Checks**
   ```bash
   aws elbv2 describe-target-health --target-group-arn {target-group-arn}
   ```

### Useful Commands

```bash
# Check ECS service status
aws ecs list-services --cluster shopbot-ecs-{env}

# View application logs
aws logs tail /ecs/shopbot-app-{env} --follow

# Force service deployment
aws ecs update-service --cluster shopbot-ecs-{env} --service shopbot-service-{env} --force-new-deployment

# Check auto scaling activity
aws application-autoscaling describe-scaling-activities --service-namespace ecs
```

## Contributing

1. Make changes in feature branches
2. Test in development environment first
3. Update documentation for infrastructure changes
4. Follow Terraform best practices for resource naming

## Support

For issues and questions:
- Check CloudWatch logs for application errors
- Review Terraform plan before applying changes
- Use AWS Console for real-time monitoring
- Consult team members for environment-specific issues