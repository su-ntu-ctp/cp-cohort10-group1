# Grafana Dashboard Setup

Simple setup for shopbot autoscaling dashboards across environments.

## Files

- **`setup-dashboard-env.sh`** - Creates environment-specific dashboard
- **`shopbot-autoscaling.json`** - Base dashboard template

## Usage

### 1. Get Data Source UIDs

Access Grafana for your environment:

- **Dev**: https://shopbot.dev.sctp-sandbox.com/grafana
- **UAT**: https://shopbot.uat.sctp-sandbox.com/grafana
- **Prod**: https://shopbot.sctp-sandbox.com/grafana

**Get admin password from AWS Secrets Manager:**

```bash
# Replace {env} with dev/uat/prod
aws secretsmanager get-secret-value --secret-id "shopbot/{env}/grafana-admin-password" --query SecretString --output text --region ap-southeast-1
```

Login: `admin` / `<password_from_secrets>`

Add data sources and copy their UIDs:

1. **CloudWatch**: Configuration → Data Sources → Add CloudWatch → Set region → Save → Copy UID from URL
2. **Prometheus**: Configuration → Data Sources → Add Prometheus → Set URL → Save → Copy UID from URL

### 2. Generate Dashboard

```bash
./setup-dashboard-env.sh <environment> <cloudwatch_uid> <prometheus_uid>

# Examples:
./setup-dashboard-env.sh dev abc123 def456
./setup-dashboard-env.sh uat ghi789 jkl012
./setup-dashboard-env.sh prod mno345 pqr678
```

### 3. Import Dashboard

1. Go to Grafana → Dashboards → Import
2. Upload the generated `shopbot-autoscaling-{env}.json` file
3. Dashboard shows environment-specific autoscaling metrics

## What It Shows

- ECS service metrics (CPU, memory, task count)
- Auto-scaling events and thresholds
- Application performance metrics
- Infrastructure health indicators
