#!/bin/bash

# Continue with existing bucket setup
set -e

echo "🔧 Continuing setup with existing bucket..."

# Set your bucket name from the error message
export S3_BUCKET=audiotracked-files-1760568631
export AWS_REGION=us-east-1

echo "Using bucket: $S3_BUCKET"

# Check if bucket exists
if aws s3 ls s3://$S3_BUCKET &> /dev/null; then
    echo "✅ Bucket exists and is accessible"
else
    echo "❌ Cannot access bucket. Please check your AWS credentials."
    exit 1
fi

# Now try to get your EC2 instance info
echo "🔍 Looking for EC2 instances..."

# Get running EC2 instances
aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,SecurityGroups[0].GroupId]' \
    --output table

echo ""
echo "📋 If you see an instance above, use its Public IP for EC2_HOST"
echo "🚀 Then run: ./simple-deploy.sh"
echo ""
echo "Or if you need to create a new EC2 instance, run:"
echo "./simple-aws-setup.sh"
