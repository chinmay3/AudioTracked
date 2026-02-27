#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$ROOT_DIR"

echo "🔍 Checking AWS IAM policies..."
echo "Make sure you've run 'aws configure' first!"

echo ""
echo "=== Searching for ECR-related policies ==="
aws iam list-policies --query 'Policies[?contains(PolicyName, `ECR`) || contains(PolicyName, `Container`)].{PolicyName:PolicyName,Arn:Arn}' --output table

echo ""
echo "=== Available EC2 policies ==="
aws iam list-policies --query 'Policies[?contains(PolicyName, `EC2`)].{PolicyName:PolicyName,Arn:Arn}' --output table

echo ""
echo "=== Available S3 policies ==="
aws iam list-policies --query 'Policies[?contains(PolicyName, `S3`)].{PolicyName:PolicyName,Arn:Arn}' --output table

echo ""
echo "=== Available IAM policies ==="
aws iam list-policies --query 'Policies[?contains(PolicyName, `IAM`)].{PolicyName:PolicyName,Arn:Arn}' --output table
