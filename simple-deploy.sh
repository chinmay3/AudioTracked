#!/bin/bash

# Simplified deployment without ECR
set -e

echo "🚀 Simple AudioTracked Deployment"
echo "================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first"
    exit 1
fi

# Get EC2 IP from environment or prompt
if [ -z "$EC2_HOST" ]; then
    read -p "Enter your EC2 instance IP: " EC2_HOST
fi

if [ -z "$EC2_KEY_PATH" ]; then
    read -p "Enter path to your .pem file: " EC2_KEY_PATH
fi

if [ -z "$S3_BUCKET" ]; then
    read -p "Enter your S3 bucket name: " S3_BUCKET
fi

echo "Using EC2 Host: $EC2_HOST"
echo "Using Key: $EC2_KEY_PATH"
echo "Using S3 Bucket: $S3_BUCKET"

# Create .env file
cat > .env << EOF
AWS_REGION=us-east-1
S3_BUCKET=$S3_BUCKET
EOF

echo "📦 Building Docker image locally..."
docker build -t audiotracked-api .

echo "🔄 Copying files to EC2..."
# Copy necessary files to EC2
scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no .env ec2-user@$EC2_HOST:~/audiotracked/
scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no docker-compose.yml ec2-user@$EC2_HOST:~/audiotracked/
scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no -r ./files ec2-user@$EC2_HOST:~/audiotracked/

# Save Docker image to tar and transfer
echo "💾 Saving Docker image..."
docker save audiotracked-api > audiotracked-api.tar

echo "📤 Uploading Docker image to EC2..."
scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no audiotracked-api.tar ec2-user@$EC2_HOST:~/

# SSH and deploy
echo "🚀 Deploying on EC2..."
ssh -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_HOST << 'EOF'
# Create directory
mkdir -p ~/audiotracked
cd ~/audiotracked

# Install Docker if not present
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Load Docker image
docker load < ~/audiotracked-api.tar

# Stop existing containers
docker-compose down || true

# Start new container
docker-compose up -d

# Check status
docker-compose ps
EOF

# Cleanup
rm audiotracked-api.tar

echo "✅ Deployment completed!"
echo "🌐 API should be available at: http://$EC2_HOST:5000"
echo "🧪 Test with: curl http://$EC2_HOST:5000/health"
