#!/bin/bash

AWS_REGION="ap-southeast-1"
ENV="dev"

echo "Checking ECS service status..."
SERVICE_STATUS=$(aws ecs describe-services --cluster shopmate-$ENV --services shopmate-service-$ENV --query "services[0].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount}" --output json --region $AWS_REGION)
echo $SERVICE_STATUS

echo "Checking security group..."
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=shopmate-sg-$ENV" --query "SecurityGroups[0].GroupId" --output text --region $AWS_REGION)
echo "Security Group ID: $SG_ID"

echo "Checking security group rules..."
aws ec2 describe-security-groups --group-ids $SG_ID --query "SecurityGroups[0].IpPermissions[*].{FromPort:FromPort,ToPort:ToPort,Protocol:IpProtocol}" --output table --region $AWS_REGION

echo "Adding port 80 rule if missing..."
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AWS_REGION || echo "Port 80 rule already exists"

echo "Checking load balancer health..."
TG_ARN=$(aws elbv2 describe-target-groups --names shopmate-tg-$ENV --query "TargetGroups[0].TargetGroupArn" --output text --region $AWS_REGION)
aws elbv2 describe-target-health --target-group-arn $TG_ARN --query "TargetHealthDescriptions[*].{IP:Target.Id,Port:Target.Port,Status:TargetHealth.State,Reason:TargetHealth.Reason}" --output table --region $AWS_REGION

echo "Restarting ECS service..."
aws ecs update-service --cluster shopmate-$ENV --service shopmate-service-$ENV --force-new-deployment --region $AWS_REGION

echo "Service restarted. It will take a few minutes for the new tasks to start."
echo "Check the status again in 2-3 minutes with:"
echo "aws elbv2 describe-target-health --target-group-arn $TG_ARN --region $AWS_REGION"