#!/bin/bash

# Get security group ID
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=shopmate-sg-dev" --query "SecurityGroups[0].GroupId" --output text --region ap-southeast-1)

echo "Security Group ID: $SG_ID"

# Check inbound rules directly
echo "Checking inbound rules..."
aws ec2 describe-security-groups --group-ids $SG_ID --query "SecurityGroups[0].IpPermissions[*].{FromPort:FromPort,ToPort:ToPort,Protocol:IpProtocol,CIDR:IpRanges[0].CidrIp}" --output table --region ap-southeast-1