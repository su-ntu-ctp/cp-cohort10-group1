#!/bin/bash
AWS_REGION=${1:-ap-southeast-1}
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws ecr get-authorization-token --query 'authorizationData[].proxyEndpoint' --output text)