# ShopMate Autoscaling Test Guide

This guide explains how to test the ECS Fargate autoscaling functionality for the ShopMate application.

## Overview

The ShopMate application is configured with AWS Application Auto Scaling to automatically adjust the number of running tasks based on CPU and memory utilization.

### Autoscaling Configuration

- **Service**: `shopmate-service-dev`
- **Cluster**: `shopmate-dev`
- **Min Capacity**: 1 task
- **Max Capacity**: 5 tasks (dev), 10 tasks (prod)
- **CPU Threshold**: 70% (scale-out when above, scale-in when below)
- **Memory Threshold**: 80% (scale-out when above, scale-in when below)

## Prerequisites

1. ShopMate application deployed to ECS Fargate
2. AWS CLI configured with appropriate permissions
3. Load balancer accessible and healthy

## Testing Autoscaling

### Step 1: Verify Current State

Check the current number of running tasks:

```bash
aws ecs describe-services --cluster shopmate-dev --services shopmate-service-dev --query 'services[0].{desired:desiredCount,running:runningCount}' --region ap-southeast-1
```

Expected output: `{"desired": 1, "running": 1}`

### Step 2: Start Monitoring

Open a dedicated terminal for monitoring and run:

```bash
chmod +x monitor-scaling.sh
./monitor-scaling.sh
```

This will continuously display:
- Current task count (desired vs running)
- Recent CPU utilization percentage

### Step 3: Generate Load

Open **3-4 additional terminals** and run the stress test in each:

```bash
chmod +x autoscaling-test.sh
./autoscaling-test.sh
```

This creates sustained CPU load by hitting the `/stress` endpoint which performs CPU-intensive calculations for 5 seconds per request.

### Step 4: Observe Scale-Out

Within **2-3 minutes** of sustained high CPU load (>70%), you should see:

1. **Task count increase**: 1 → 2 → 3 (or higher based on load)
2. **CPU utilization**: Initially high (>70%), then decreasing as new tasks come online
3. **Brief response delays**: Normal during task startup and load balancer registration

### Step 5: Test Scale-In

1. **Stop all load tests** (Ctrl+C in all terminals running the stress test)
2. **Continue monitoring** with `./monitor-scaling.sh`
3. **Wait 10-15 minutes** for scale-in to occur
4. **Observe gradual scale-in**: 3 → 2 → 1 (gradual reduction to prevent instability)

## Verification Commands

### Check Autoscaling Configuration

```bash
# Verify autoscaling target exists
aws application-autoscaling describe-scalable-targets --service-namespace ecs --resource-ids service/shopmate-dev/shopmate-service-dev --region ap-southeast-1

# Check scaling policies
aws application-autoscaling describe-scaling-policies --service-namespace ecs --resource-id service/shopmate-dev/shopmate-service-dev --region ap-southeast-1
```

### Check Scaling Activities

```bash
# View recent scaling activities
aws application-autoscaling describe-scaling-activities --service-namespace ecs --resource-id service/shopmate-dev/shopmate-service-dev --region ap-southeast-1
```

### Check CloudWatch Alarms

```bash
# Check CPU alarm status
aws cloudwatch describe-alarms --alarm-name-prefix "TargetTracking-service/shopmate-dev/shopmate-service-dev" --region ap-southeast-1
```

### Manual CPU Check

```bash
# Get recent CPU utilization
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=shopmate-service-dev Name=ClusterName,Value=shopmate-dev --start-time $(date -u -v-10M +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 60 --statistics Average --region ap-southeast-1
```

## Expected Behavior

### Scale-Out (Load Increase)
- **Trigger**: CPU > 70% for 2-3 minutes
- **Response Time**: 2-3 minutes
- **Pattern**: Gradual increase (1 → 2 → 3 → etc.)
- **Side Effects**: Brief response delays during task startup

### Scale-In (Load Decrease)
- **Trigger**: CPU < 70% for 10-15 minutes
- **Response Time**: 10-15 minutes (intentionally slower)
- **Pattern**: Gradual decrease (3 → 2 → 1)
- **Side Effects**: Minimal impact due to connection draining

## Troubleshooting

### No Scaling Occurs
1. Check if autoscaling policies exist
2. Verify CPU actually exceeds 70% threshold
3. Ensure load is sustained (not just brief spikes)
4. Check ECS service events for errors

### Tasks Fail to Start
1. Check ECS service events
2. Verify sufficient cluster capacity
3. Check security group and subnet configuration
4. Verify ECR image accessibility

### Slow Response During Scaling
- This is normal behavior during autoscaling events
- New tasks need time to start and pass health checks
- Load balancer needs time to register new targets

## Files

- `autoscaling-test.sh` - Generates CPU load for testing
- `monitor-scaling.sh` - Real-time monitoring of scaling activity
- `app.js` - Contains `/stress` endpoint for CPU-intensive testing

## Cost Considerations

- Autoscaling helps optimize costs by scaling down during low usage
- Monitor CloudWatch metrics to understand scaling patterns
- Consider adjusting thresholds based on actual usage patterns
- Remember that each task consumes CPU/memory resources and incurs costs

## Production Recommendations

1. **Fine-tune thresholds** based on actual traffic patterns
2. **Set appropriate cooldown periods** to prevent excessive scaling
3. **Monitor scaling activities** regularly
4. **Set up CloudWatch alarms** for scaling events
5. **Test autoscaling** during maintenance windows
6. **Document scaling behavior** for your specific workload