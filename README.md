# ShopBot E-commerce Application

**Contributors:** Vrushali Bavare and Ramya Rajendran  
**Group 1 - NTU SCTP Cohort 10**

A cloud-native e-commerce application with Node.js/Express backend, comprehensive monitoring, auto-scaling, and multi-environment CI/CD deployment on AWS ECS Fargate.

## 🏗️ Architecture

```
Internet → Route 53 → ALB (HTTPS) → ECS Fargate → DynamoDB
                         ↓
                   CloudWatch Logs
                         ↓
               Prometheus & Grafana
```

## 📁 Project Structure

```
cp-cohort10-group1/
├── app/                    # Node.js E-commerce Application
│   ├── controllers/        # Business logic (products, cart, orders)
│   ├── models/            # Data models (DynamoDB integration)
│   ├── routes/            # API routes (products, cart, orders, AI)
│   ├── views/             # EJS templates (home, products, cart, checkout)
│   ├── public/            # Static assets (CSS, JS, images)
│   ├── utils/             # Utilities (DynamoDB helper)
│   ├── Dockerfile.*       # Multi-environment Docker builds
│   └── package.json       # Dependencies & scripts
├── infra/                 # Infrastructure as Code
│   ├── terraform/         # Terraform configurations
│   │   ├── shared/        # Shared resources (OIDC, ECR)
│   │   ├── *.tf          # Infrastructure modules
│   │   └── terraform.tfvars.*  # Environment-specific configs
│   ├── grafana-dashboards/ # Pre-configured monitoring dashboards
│   └── Dockerfile.prometheus # Prometheus monitoring container
├── .github/workflows/     # CI/CD pipelines (dev, staging, prod)
├── scripts/               # Deployment & utility scripts
├── docs/                  # Project documentation
├── testing/               # Test configurations
└── README.md             # This file
```

## 🚀 Features

### E-commerce Application
- **Product Catalog**: Browse products with detailed views
- **Shopping Cart**: Add/remove items with session persistence
- **Order Management**: Complete checkout and order tracking
- **AI Chatbot**: Customer support integration
- **Prometheus Metrics**: Business & technical KPIs
- **Health Monitoring**: Comprehensive health checks
- **Rate Limiting**: Protection against abuse

### Cloud Infrastructure
- **Multi-Environment**: Dev, Staging, Production isolation
- **Auto-Scaling**: CPU/Memory-based with custom metrics
- **Security**: HTTPS-only, VPC isolation, IAM least privilege
- **Monitoring**: Prometheus, Grafana, CloudWatch integration
- **CI/CD**: GitHub Actions with security scanning
- **Container Security**: Distroless images, vulnerability scanning

## 🌍 Environment Configuration

| Environment | Domain | CPU | Memory | Scaling | Image Type |
|-------------|--------|-----|--------|---------|------------|
| **Development** | `dev-shopbot.sctp-sandbox.com` | 256 | 512 MB | 1-3 tasks | Ubuntu (debug) |
| **Staging** | `staging-shopbot.sctp-sandbox.com` | 512 | 1024 MB | 1-5 tasks | Distroless + debug |
| **Production** | `shopbot.sctp-sandbox.com` | 1024 | 2048 MB | 3-10 tasks | Pure distroless |

## 🛠️ Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.11.4
- Docker for container builds
- Node.js 18+ for local development
- GitHub OIDC configured for CI/CD

## 🚀 Quick Start

### Local Development
```bash
cd app
npm install
npm run dev
# Access: http://localhost:3000
```

### Deploy Infrastructure
```bash
# Deploy shared resources (ECR, OIDC)
./scripts/deploy-shared.sh

# Deploy environment-specific infrastructure
./deploy-env-dev.sh
./deploy-env-staging.sh
./deploy-env-prod.sh
```

### Build & Push Images
```bash
./scripts/dockerbuild.sh
```

## 🔄 CI/CD Pipeline

### Workflow Triggers
- **Development**: PR merge to `dev` → Auto-deploy to dev environment
- **Staging**: PR merge to `staging` → Auto-deploy to staging environment
- **Production**: PR merge to `main` → Auto-deploy to production environment

### Security Gates
- **Infrastructure**: Terraform validation, Checkov security scanning
- **Application**: npm audit, dependency vulnerability checks
- **Containers**: Trivy security scanning (CRITICAL/HIGH severity blocking)
- **Deployment**: Only proceeds after all security scans pass

## 📊 Monitoring & Metrics

### Application Metrics
- **Business KPIs**: Orders created, cart items, product views, revenue
- **Performance**: HTTP requests, response times, error rates
- **Security**: Rate limiting events, failed requests

### Infrastructure Metrics
- **ECS**: CPU/Memory utilization, task count, scaling events
- **Load Balancer**: Request count, latency, target health
- **DynamoDB**: Read/write capacity, throttling events

### Access Points
- **Application**: `https://{env}-shopbot.sctp-sandbox.com`
- **Prometheus**: `https://{env}-shopbot.sctp-sandbox.com/prometheus`
- **Grafana**: `https://{env}-shopbot.sctp-sandbox.com/grafana`
  - Username: `admin` / Password: `admin123`

## 🔒 Security Features

### Network Security
- VPC with public/private subnets
- Security groups with restrictive rules
- HTTPS-only with SSL termination

### Application Security
- Rate limiting (100 req/15min general, 10 req/15min orders)
- Input validation and sanitization
- Session security with DynamoDB backend
- Request/response timeouts

### Container Security
- Multi-stage builds with distroless base images
- Non-root user execution
- Vulnerability scanning with Trivy
- Minimal attack surface

### Infrastructure Security
- IAM roles with least privilege
- Encrypted storage (DynamoDB, Secrets Manager)
- GitHub OIDC for secure CI/CD
- Parameter Store for sensitive configurations

## 🏗️ Infrastructure Components

### Core Services
- **ECS Fargate**: Serverless container hosting
- **Application Load Balancer**: HTTPS traffic distribution
- **DynamoDB**: NoSQL database (products, sessions, orders)
- **ECR**: Private container registry with lifecycle policies
- **Route 53**: DNS management with health checks
- **ACM**: Automated SSL certificate management

### Monitoring Stack
- **Prometheus**: Metrics collection with custom business metrics
- **Grafana**: Visualization with pre-configured dashboards
- **CloudWatch**: AWS native monitoring and log aggregation

### Security & Networking
- **VPC**: Isolated network environment
- **Security Groups**: Network access control
- **IAM**: Role-based access control
- **Secrets Manager**: Encrypted credential storage

## 🔧 Troubleshooting

### Health Checks
```bash
# Application health
curl https://{env}-shopbot.sctp-sandbox.com/health

# Prometheus metrics
curl https://{env}-shopbot.sctp-sandbox.com/metrics

# Test auto-scaling
curl "https://{env}-shopbot.sctp-sandbox.com/stress?duration=30000"
```

### Common Issues
```bash
# Container startup issues
aws ecs describe-services --cluster shopbot-ecs-{env} --services shopbot-service-{env}
aws logs tail /ecs/shopbot-app-{env} --follow

# Force deployment
aws ecs update-service --cluster shopbot-ecs-{env} --service shopbot-service-{env} --force-new-deployment

# Auto-scaling activity
aws application-autoscaling describe-scaling-activities --service-namespace ecs
```

## 🤝 Development Workflow

### Branch Strategy
- `main` → Production environment
- `staging` → Staging environment  
- `dev` → Development environment
- Feature branches → Create from `dev`

### Deployment Flow
1. Create feature branch from `dev`
2. Develop and test locally
3. Create PR to `dev` → Auto-deploy to dev environment
4. Test in dev, then PR `dev` → `staging`
5. Test in staging, then PR `staging` → `main`
6. Production deployment with monitoring

## 📚 Documentation

- **Infrastructure**: [Terraform Documentation](./infra/terraform/README.md)
- **Monitoring**: [Grafana Dashboards](./infra/grafana-dashboards/README.md)
- **Testing**: [Testing Guide](./testing/README.md)
- **API**: [API Documentation](./docs/README.md)

## 📞 Support

**Team Contacts:**
- **Vrushali Bavare**: Infrastructure & DevOps
- **Ramya Rajendran**: Application Development & Monitoring

**For Issues:**
- Check CloudWatch logs for application errors
- Review GitHub Actions for CI/CD pipeline issues
- Use AWS Console for real-time infrastructure monitoring
- Monitor Grafana dashboards for performance insights

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.