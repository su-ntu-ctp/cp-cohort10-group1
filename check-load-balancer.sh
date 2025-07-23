#!/bin/bash

echo "Checking Load Balancer status..."
aws elbv2 describe-load-balancers --names shopmate-alb-dev --query "LoadBalancers[0].{DNSName:DNSName,State:State.Code,Type:Type}" --output table --region ap-southeast-1

echo -e "\nChecking Target Group status..."
TG_ARN=$(aws elbv2 describe-target-groups --names shopmate-tg-dev --query "TargetGroups[0].TargetGroupArn" --output text --region ap-southeast-1)

echo "Target Group ARN: $TG_ARN"

echo -e "\nChecking Target Health..."
aws elbv2 describe-target-health --target-group-arn $TG_ARN --query "TargetHealthDescriptions[*].{IP:Target.Id,Port:Target.Port,Status:TargetHealth.State,Reason:TargetHealth.Reason,Description:TargetHealth.Description}" --output table --region ap-southeast-1

echo -e "\nChecking Listener..."
aws elbv2 describe-listeners --load-balancer-arn $(aws elbv2 describe-load-balancers --names shopmate-alb-dev --query "LoadBalancers[0].LoadBalancerArn" --output text --region ap-southeast-1) --query "Listeners[*].{Port:Port,Protocol:Protocol,DefaultAction:DefaultActions[0].Type}" --output table --region ap-southeast-1