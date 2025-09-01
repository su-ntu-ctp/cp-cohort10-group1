# Grafana Dashboard Setup

Simple setup for shopbot autoscaling dashboards across environments.

## Files

- **`setup-dashboard-env.sh`** - Creates environment-specific dashboard
- **`shopbot-autoscaling.json`** - Base dashboard template

## Usage

### 1. Get Data Source UIDs

Access Grafana for your environment:

- **Dev**: https://dev-shopbot.sctp-sandbox.com/grafana
- **UAT**: https://staging-shopbot.uat.sctp-sandbox.com/grafana
- **Prod**: https://shopbot.sctp-sandbox.com/grafana

**Get admin password from AWS Secrets Manager:**

```bash
# Replace {env} with dev/staging/prod
aws secretsmanager get-secret-value --secret-id "shopbot/{env}/grafana-admin-password" --query SecretString --output text --region ap-southeast-1
```

Login: `admin` / `<password_from_secrets>`

Add data sources and copy their UIDs:

#### CloudWatch Data Source Setup:
1. Go to **Configuration** → **Data Sources** → **Add data source**
2. Select **CloudWatch**
3. **Important Settings:**
   - **Authentication Provider**: `AWS SDK Default`
   - **Default Region**: `ap-southeast-1`
   - **Assume Role ARN**: Leave empty (uses ECS task role)
   - **External ID**: Leave empty
   - **Endpoint**: Leave empty (uses default)
   - **Custom Metrics Namespaces**: Leave empty
4. Click **Save & Test** (should show green checkmark)
5. **Copy the UID** from the browser URL (e.g., `cloudwatch-uid-abc123`)

#### Prometheus Data Source Setup:
1. Go to **Configuration** → **Data Sources** → **Add data source**
2. Select **Prometheus**
3. **Important Settings:**
   - **URL**: `https://dev-shopbot.sctp-sandbox.com/prometheus` (replace with your environment)
   - **Access**: `Server (default)`
   - **Basic Auth**: Disabled
   - **Skip TLS Verify**: Disabled
   - **HTTP Method**: `GET`
   - **Scrape interval**: `15s`
4. Click **Save & Test** (should show green checkmark)
5. **Copy the UID** from the browser URL (e.g., `prometheus-uid-def456`)

**Note**: The CloudWatch data source uses the ECS task role for authentication, so no additional credentials are needed.

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
