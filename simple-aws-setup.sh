#!/bin/bash

# Simplified AWS setup - minimal permissions needed
set -e

echo "🏗️ Simplified AWS Setup for AudioTracked"
echo "========================================"

# Check AWS CLI
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Please configure AWS CLI first: aws configure"
    exit 1
fi

# Get region
REGION=${AWS_REGION:-us-east-1}
echo "Using region: $REGION"

# Create S3 bucket
BUCKET_NAME="audiotracked-files-$(date +%s)"
echo "🪣 Creating S3 bucket: $BUCKET_NAME"

aws s3 mb s3://$BUCKET_NAME --region $REGION

# Note: We're not setting up public bucket access to avoid permission issues
# The app will use signed URLs instead of public URLs

# Create security group for EC2
echo "🔒 Creating security group..."
SG_ID=$(aws ec2 create-security-group \
    --group-name audiotracked-simple-sg \
    --description "AudioTracked Security Group" \
    --region $REGION \
    --query 'GroupId' \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
        --group-names audiotracked-simple-sg \
        --region $REGION \
        --query 'SecurityGroups[0].GroupId' \
        --output text)

# Allow HTTP and SSH access
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 5000 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "Port 5000 rule may already exist"

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "SSH rule may already exist"

# Create key pair
KEY_NAME="audiotracked-key-$(date +%s)"
echo "🔑 Creating key pair: $KEY_NAME"

aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --region $REGION \
    --query 'KeyMaterial' \
    --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem

# Find latest Amazon Linux 2 AMI
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text \
    --region $REGION)

echo "Using AMI: $AMI_ID"

# Launch EC2 instance
echo "🚀 Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t3.micro \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance ID: $INSTANCE_ID"

# Wait for instance
echo "⏳ Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo ""
echo "🎉 Setup completed!"
echo "==================="
echo "S3 Bucket: $BUCKET_NAME"
echo "EC2 Instance: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "Key File: ${KEY_NAME}.pem"
echo ""
echo "📋 Set these environment variables:"
echo "export S3_BUCKET=$BUCKET_NAME"
echo "export EC2_HOST=$PUBLIC_IP"
echo "export EC2_KEY_PATH=${KEY_NAME}.pem"
echo "export AWS_REGION=$REGION"
echo ""
echo "🚀 Now run: ./simple-deploy.sh"
