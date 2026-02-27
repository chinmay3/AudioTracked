#!/bin/bash

# User data script for EC2 instance
# This script runs when the EC2 instance starts up

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create deployment directory
mkdir -p /home/ec2-user/audiotracked-deploy

# Set up log rotation for Docker
cat > /etc/logrotate.d/docker << EOF
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF

echo "User data script completed" > /var/log/user-data.log
