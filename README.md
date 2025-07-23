# ShopMate E-commerce Application

A simple e-commerce application built with Node.js and Express, designed to be easily containerized and deployed to AWS ECS Fargate.

## Features

- Product listing and details
- Shopping cart functionality
- Checkout process
- Order management
- Responsive design

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- Docker and Docker Compose (for containerized development)
- AWS CLI configured with appropriate permissions
- Terraform (for infrastructure deployment)

## Getting Started

### Local Development

1. Clone the repository:
   ```
   git clone <repository-url>
   cd shopmate-new
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Start the development server:
   ```
   npm run dev
   ```

4. Open your browser and navigate to `http://localhost:3000`

### Using Docker

1. Build and start the container:
   ```
   docker-compose up
   ```

2. Open your browser and navigate to `http://localhost:3000`

## Deployment to AWS ECS Fargate

### Option 1: Using the Deployment Script

The easiest way to deploy is using the provided deployment script:

```
./deploy.sh [environment] [region]
```

For example:
```
./deploy.sh dev ap-southeast-1
```

This will:
1. Build and push the Docker image to ECR
2. Apply the Terraform configuration for the specified environment
3. Output the application URL and CloudWatch dashboard URL

### Option 2: Manual Deployment with Terraform

1. Build and tag the Docker image:
   ```
   docker build -t shopmate .
   docker tag shopmate:latest <aws-account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/shopmate:latest
   ```

2. Push the image to ECR:
   ```
   aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
   docker push <aws-account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/shopmate:latest
   ```

3. Apply the Terraform configuration:
   ```
   cd terraform/environments/dev  # or uat, prod
   terraform init
   terraform apply
   ```

## Environment Configuration

The application supports three environments:

- **dev**: Development environment (1 instance)
- **uat**: User Acceptance Testing environment (2 instances)
- **prod**: Production environment (3 instances)

Each environment has its own Terraform configuration in `terraform/environments/<env>`.

## Monitoring

The application includes a CloudWatch dashboard that shows:

- CPU and memory utilization
- Application logs
- Request counts and latency

Access the dashboard via the AWS Console or use the URL output by the deployment script.

## Troubleshooting

### Common Issues and Solutions

1. **Security Group Configuration**
   - **Issue**: Load balancer not accessible on port 80
   - **Solution**: Add inbound rule for port 80 to the security group
   ```bash
   # Get security group ID
   SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=shopmate-sg-dev" --query "SecurityGroups[0].GroupId" --output text --region ap-southeast-1)
   
   # Add rule for port 80
   aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region ap-southeast-1
   ```

2. **DynamoDB Integration**
   - **Issue**: "products.forEach is not a function" error
   - **Solution**: Ensure proper error handling in models and views for DynamoDB responses
   - Check the product model to ensure it always returns an array
   - Add checks in EJS templates: `<% if (Array.isArray(products) && products.length > 0) { %>`

3. **Docker Image Architecture**
   - **Issue**: Container fails to start on Fargate when built on Apple Silicon Mac
   - **Solution**: Build for the correct architecture
   ```bash
   docker buildx build --platform=linux/amd64 --load -t shopmate:latest .
   ```

4. **ECR Login Issues**
   - **Issue**: "docker login requires at most 1 argument" error
   - **Solution**: Use the correct ECR login command format
   ```bash
   aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin $(aws ecr get-authorization-token --query 'authorizationData[].proxyEndpoint' --output text)
   ```

5. **Terraform State Issues**
   - **Issue**: Terraform fails with "resource already exists" errors
   - **Solution**: Import existing resources into Terraform state
   ```bash
   terraform import module.shopmate.aws_iam_role.ecs_task_execution_role shopmate-execution-role-dev
   ```

### Diagnostic Scripts

The repository includes several diagnostic scripts to help troubleshoot issues:

- `check-security-group.sh` - Checks security group configuration
- `check-ecs-status.sh` - Checks ECS service and task status
- `check-load-balancer.sh` - Checks load balancer and target health
- `redeploy.sh` - Rebuilds and redeploys the application

### Viewing Logs

To view application logs:

```bash
aws logs get-log-events --log-group-name /ecs/shopmate-dev --log-stream-name shopmate/shopmate/[TASK_ID] --region ap-southeast-1
```

Replace [TASK_ID] with the actual task ID from:

```bash
aws ecs list-tasks --cluster shopmate-dev --region ap-southeast-1
```

## Project Structure

- `app.js` - Main application entry point
- `models/` - Data models
- `controllers/` - Request handlers
- `routes/` - API routes
- `views/` - EJS templates
- `public/` - Static assets (CSS, JavaScript, images)
- `Dockerfile` - Docker configuration
- `docker-compose.yml` - Docker Compose configuration
- `terraform/` - Infrastructure as Code for AWS deployment

## License

MIT