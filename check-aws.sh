#!/bin/bash

echo "Checking AWS configuration..."
aws configure list

echo -e "\nChecking AWS connectivity..."
echo "Testing connectivity to IAM..."
curl -s -o /dev/null -w "%{http_code}" https://iam.amazonaws.com

echo -e "\nTesting connectivity to ECR..."
curl -s -o /dev/null -w "%{http_code}" https://api.ecr.ap-southeast-1.amazonaws.com

echo -e "\nChecking DNS resolution..."
nslookup iam.amazonaws.com
nslookup api.ecr.ap-southeast-1.amazonaws.com

echo -e "\nChecking AWS CLI version..."
aws --version