#!/bin/bash

# Get security group ID
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=shopmate-sg-dev" --query "SecurityGroups[0].GroupId" --output text --region ap-southeast-1)

echo "Security Group ID: $SG_ID"
echo "Adding rule for port 80..."

# Add rule for port 80
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region ap-southeast-1

echo "Security group updated. Checking new rules:"
aws ec2 describe-security-groups --group-ids $SG_ID --query "SecurityGroups[0].IpPermissions[*].{FromPort:FromPort,ToPort:ToPort,Protocol:IpProtocol,CIDR:IpRanges[0].CidrIp}" --output table --region ap-southeast-1