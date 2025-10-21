#!/bin/bash

# AWS Setup Script for AudioTracked
# This script sets up the required AWS resources (S3 bucket, EC2 instance, etc.)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏗️  AWS Setup for AudioTracked${NC}"
echo "================================"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if jq is installed (for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq is not installed. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq
    else
        sudo apt-get update && sudo apt-get install -y jq
    fi
fi

# Configuration
REGION=${AWS_REGION:-us-east-1}
BUCKET_NAME=${S3_BUCKET:-audiotracked-files-$(date +%s)}
PROJECT_NAME="audiotracked"

echo -e "${BLUE}🏷️  Configuration:${NC}"
echo "Region: $REGION"
echo "S3 Bucket: $BUCKET_NAME"

# Create S3 bucket
echo -e "${YELLOW}🪣 Creating S3 bucket...${NC}"
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Enable bucket versioning
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

# Note: Using signed URLs instead of public bucket policy to avoid permission issues
# The Flask app will generate signed URLs for file downloads

echo -e "${GREEN}✅ S3 bucket created and configured${NC}"

# Create ECR repository for Docker images
echo -e "${YELLOW}📦 Creating ECR repository...${NC}"
aws ecr create-repository --repository-name audiotracked-api --region $REGION || echo "Repository may already exist"

# Get ECR login token and login
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com

echo -e "${GREEN}✅ ECR repository ready${NC}"

# Create security group for EC2
echo -e "${YELLOW}🔒 Creating security group...${NC}"
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name ${PROJECT_NAME}-sg \
    --description "Security group for AudioTracked API" \
    --region $REGION \
    --query 'GroupId' \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
        --group-names ${PROJECT_NAME}-sg \
        --region $REGION \
        --query 'SecurityGroups[0].GroupId' \
        --output text)

# Allow HTTP traffic on port 5000
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 5000 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "Rule may already exist"

# Allow SSH access
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "Rule may already exist"

echo -e "${GREEN}✅ Security group created${NC}"

# Create IAM role for EC2
echo -e "${YELLOW}👤 Creating IAM role...${NC}"
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
    --role-name ${PROJECT_NAME}-ec2-role \
    --assume-role-policy-document file://trust-policy.json || echo "Role may already exist"

# Create and attach policy for S3 access
cat > s3-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::$BUCKET_NAME",
        "arn:aws:s3:::$BUCKET_NAME/*"
      ]
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name ${PROJECT_NAME}-ec2-role \
    --policy-name S3Access \
    --policy-document file://s3-policy.json

aws iam create-instance-profile --instance-profile-name ${PROJECT_NAME}-profile || echo "Profile may already exist"
aws iam add-role-to-instance-profile \
    --instance-profile-name ${PROJECT_NAME}-profile \
    --role-name ${PROJECT_NAME}-ec2-role || echo "Role may already be attached"

rm trust-policy.json s3-policy.json

echo -e "${GREEN}✅ IAM role created${NC}"

# Find latest Amazon Linux 2 AMI
echo -e "${YELLOW}🔍 Finding latest Amazon Linux 2 AMI...${NC}"
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text \
    --region $REGION)

echo "Using AMI: $AMI_ID"

# Create key pair (optional)
KEY_NAME=${PROJECT_NAME}-key
echo -e "${YELLOW}🔑 Creating key pair...${NC}"
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --region $REGION \
    --query 'KeyMaterial' \
    --output text > ${KEY_NAME}.pem 2>/dev/null || echo "Key pair may already exist"

if [ -f "${KEY_NAME}.pem" ]; then
    chmod 400 ${KEY_NAME}.pem
    echo -e "${GREEN}✅ Key pair created: ${KEY_NAME}.pem${NC}"
fi

# Launch EC2 instance
echo -e "${YELLOW}🚀 Launching EC2 instance...${NC}"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t3.micro \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --iam-instance-profile Name=${PROJECT_NAME}-profile \
    --user-data file://user-data.sh \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance ID: $INSTANCE_ID"

# Wait for instance to be running
echo -e "${YELLOW}⏳ Waiting for instance to be running...${NC}"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo -e "${GREEN}🎉 AWS setup completed!${NC}"
echo "=================================="
echo -e "${BLUE}📋 Summary:${NC}"
echo "S3 Bucket: $BUCKET_NAME"
echo "EC2 Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "Security Group: $SECURITY_GROUP_ID"
echo "Key Pair: $KEY_NAME.pem"
echo ""
echo -e "${YELLOW}⚙️  Environment variables to set:${NC}"
echo "export AWS_REGION=$REGION"
echo "export S3_BUCKET=$BUCKET_NAME"
echo "export EC2_HOST=$PUBLIC_IP"
echo "export EC2_KEY_PATH=${KEY_NAME}.pem"
echo "export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)"
echo ""
echo -e "${BLUE}🌐 Your API will be available at: http://$PUBLIC_IP:5000${NC}"
