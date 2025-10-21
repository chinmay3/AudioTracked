#!/bin/bash

# Direct deployment to EC2 without requiring local Docker
set -e

echo "🚀 Direct AudioTracked Deployment to EC2"
echo "========================================"

# Check environment variables
if [ -z "$EC2_HOST" ] || [ -z "$S3_BUCKET" ] || [ -z "$EC2_KEY_PATH" ]; then
    echo "❌ Missing required environment variables"
    echo "Please set: EC2_HOST, S3_BUCKET, EC2_KEY_PATH"
    exit 1
fi

echo "Using EC2 Host: $EC2_HOST"
echo "Using S3 Bucket: $S3_BUCKET"
echo "Using Key: $EC2_KEY_PATH"

# Create .env file
cat > .env << EOF
AWS_REGION=${AWS_REGION:-us-east-1}
S3_BUCKET=$S3_BUCKET
EOF

echo "📤 Copying files to EC2..."

# Create the deployment directory on EC2 and copy files
ssh -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_HOST << 'EOF'
mkdir -p ~/audiotracked-deploy
EOF

# Copy application files
scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no app.py ec2-user@$EC2_HOST:~/audiotracked-deploy/
scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no utils.py ec2-user@$EC2_HOST:~/audiotracked-deploy/
scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no requirements.txt ec2-user@$EC2_HOST:~/audiotracked-deploy/
scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no Dockerfile ec2-user@$EC2_HOST:~/audiotracked-deploy/
scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no docker-compose.yml ec2-user@$EC2_HOST:~/audiotracked-deploy/
scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no .env ec2-user@$EC2_HOST:~/audiotracked-deploy/

# Copy sample files directory if it exists
if [ -d "files" ]; then
    echo "📤 Copying sample files..."
    scp -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no -r files ec2-user@$EC2_HOST:~/audiotracked-deploy/
fi

echo "🚀 Deploying on EC2..."

# SSH and deploy
ssh -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_HOST << EOF
cd ~/audiotracked-deploy

# Update system
sudo yum update -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    sudo systemctl enable docker
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Make sure Docker is running
sudo service docker restart

# Wait a moment for Docker to be ready
sleep 10

# Stop any existing containers
sudo docker-compose down || true

# Create necessary directories
mkdir -p files temp_uploads

# Set environment variables for Docker
export AWS_ACCESS_KEY_ID=\$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=\$(aws configure get aws_secret_access_key)

# Build and start the application
sudo docker-compose up --build -d

# Wait for container to start
sleep 15

# Check if container is running
sudo docker-compose ps

# Check logs
echo "=== Container logs ==="
sudo docker-compose logs audiotracked-api | tail -20

echo "Deployment completed!"
EOF

echo "✅ Deployment completed!"
echo "🌐 Testing API endpoint..."

# Test the API
sleep 10
curl -s "http://$EC2_HOST:5000/health" || echo "API might still be starting up..."

echo ""
echo "🎉 Deployment Summary:"
echo "======================"
echo "API URL: http://$EC2_HOST:5000"
echo "Health Check: http://$EC2_HOST:5000/health"
echo ""
echo "📱 To use the web interface:"
echo "1. Open web_interface.html in your browser"
echo "2. Update the API_BASE_URL to: http://$EC2_HOST:5000/api"
