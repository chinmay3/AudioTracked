#!/bin/bash

# AudioTracked Deployment Script
# This script deploys the AudioTracked app to AWS EC2 with Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎵 AudioTracked Deployment Script${NC}"
echo "=================================="

# Check if required environment variables are set
required_vars=("AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_REGION" "S3_BUCKET" "EC2_HOST")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Error: $var environment variable is not set${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Environment variables configured${NC}"

# Create .env file for Docker
echo "Creating .env file..."
cat > .env << EOF
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
AWS_REGION=${AWS_REGION}
S3_BUCKET=${S3_BUCKET}
EOF

echo -e "${GREEN}✅ .env file created${NC}"

# Build Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
docker build -t audiotracked-api .

echo -e "${GREEN}✅ Docker image built successfully${NC}"

# Tag and push to a registry (if using AWS ECR)
echo -e "${YELLOW}📦 Tagging image for AWS ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
docker tag audiotracked-api:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/audiotracked-api:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/audiotracked-api:latest

echo -e "${GREEN}✅ Image pushed to ECR${NC}"

# Deploy to EC2
echo -e "${YELLOW}🚀 Deploying to EC2...${NC}"

# Create deployment directory on EC2
ssh -i ${EC2_KEY_PATH} ec2-user@${EC2_HOST} "mkdir -p ~/audiotracked-deploy"

# Copy deployment files
scp -i ${EC2_KEY_PATH} docker-compose.yml ec2-user@${EC2_HOST}:~/audiotracked-deploy/
scp -i ${EC2_KEY_PATH} .env ec2-user@${EC2_HOST}:~/audiotracked-deploy/

# SSH into EC2 and run deployment
ssh -i ${EC2_KEY_PATH} ec2-user@${EC2_HOST} << 'EOF'
cd ~/audiotracked-deploy

# Install Docker and Docker Compose if not present
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Pull latest image and restart containers
docker-compose down || true
docker-compose pull
docker-compose up -d

# Check if container is running
docker-compose ps

echo "Deployment completed!"
EOF

echo -e "${GREEN}🎉 Deployment successful!${NC}"
echo -e "${BLUE}🌐 Your API should be available at: http://${EC2_HOST}:5000${NC}"
