#!/bin/bash
# Get AWS credentials from local configuration
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
export AWS_REGION=$(aws configure get region || echo "us-east-1")
export S3_BUCKET="audiotracked-files-1760568809"

echo "Starting container with AWS credentials..."
ssh -i audiotracked-key-1760568814.pem ec2-user@54.204.110.168 << INNER_SCRIPT
cd ~/audiotracked-deploy
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY  
export AWS_REGION=$AWS_REGION
export S3_BUCKET=$S3_BUCKET

sudo AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY AWS_REGION=\$AWS_REGION S3_BUCKET=\$S3_BUCKET /usr/local/bin/docker-compose up -d
INNER_SCRIPT
