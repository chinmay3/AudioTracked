# AudioTracked Deployment Guide

This guide covers deploying your AudioTracked audio steganography application to AWS with a Swift iOS frontend.

## 🏗️ Architecture Overview

- **Backend**: Flask API running on AWS EC2 (Docker containerized)
- **Storage**: AWS S3 buckets for file storage
- **Frontend**: Swift iOS application
- **Containerization**: Docker with docker-compose

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Docker** and **Docker Compose** installed locally
4. **Xcode** for iOS development
5. **SSH key pair** for EC2 access

## 🚀 Quick Deployment Steps

### 1. AWS Setup

Run the AWS setup script to create all necessary resources:

```bash
# Make sure AWS CLI is configured
aws configure

# Run the setup script
./aws-setup.sh
```

This script will:
- Create S3 bucket for file storage
- Set up ECR repository for Docker images
- Create security groups with proper rules
- Launch EC2 instance with necessary IAM roles

### 2. Environment Configuration

After running `aws-setup.sh`, you'll get environment variables to set:

```bash
export AWS_REGION=us-east-1
export S3_BUCKET=your-bucket-name
export EC2_HOST=your-ec2-ip
export EC2_KEY_PATH=audiotracked-key.pem
export AWS_ACCOUNT_ID=your-account-id
```

### 3. Deploy Backend

Deploy the Flask API to EC2:

```bash
./deploy.sh
```

This will:
- Build Docker image locally
- Push to AWS ECR
- Deploy to EC2 instance
- Start the API service

### 4. Configure iOS App

Update the API endpoint in your iOS app:

1. Open `ios_frontend/AudioTracked/AudioTracked/APIService.swift`
2. Update the `baseURL` constant:
   ```swift
   private let baseURL = "http://YOUR_EC2_IP:5000/api"
   ```

### 5. Build and Run iOS App

Open the iOS project in Xcode:

```bash
open ios_frontend/AudioTracked/AudioTracked.xcodeproj
```

Build and run on a device or simulator.

## 🔧 Manual Configuration

### AWS Resources Created

1. **S3 Bucket**: Stores watermarked files and metadata
2. **EC2 Instance**: Runs the Docker container
3. **ECR Repository**: Stores Docker images
4. **IAM Role**: Allows EC2 to access S3
5. **Security Group**: Allows HTTP traffic on port 5000

### API Endpoints

The Flask API provides these endpoints:

- `GET /health` - Health check
- `POST /api/audio-watermark` - Embed audio in audio
- `POST /api/audio-watermark/extract` - Extract embedded audio
- `POST /api/image-watermark` - Embed image in audio
- `POST /api/text-watermark` - Embed text in audio
- `POST /api/text-watermark/extract` - Extract embedded text

### Environment Variables

Required environment variables for the backend:

```bash
AWS_REGION=us-east-1
S3_BUCKET=your-bucket-name
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

## 🐛 Troubleshooting

### Backend Issues

1. **Container won't start**: Check EC2 instance logs
   ```bash
   ssh -i your-key.pem ec2-user@your-ip
   cd ~/audiotracked-deploy
   docker-compose logs
   ```

2. **S3 access denied**: Verify IAM role is attached to EC2 instance

3. **Port not accessible**: Check security group allows inbound traffic on port 5000

### iOS App Issues

1. **Network errors**: Verify EC2 IP is correct and accessible
2. **File picker issues**: Ensure proper permissions in Info.plist

## 📁 Project Structure

```
AudioTracked/
├── app.py                    # Flask API backend
├── utils.py                  # Steganography functions
├── requirements.txt          # Python dependencies
├── Dockerfile               # Docker configuration
├── docker-compose.yml       # Container orchestration
├── deploy.sh                # Deployment script
├── aws-setup.sh             # AWS resource creation
├── user-data.sh            # EC2 initialization
├── ios_frontend/            # Swift iOS app
│   └── AudioTracked/
│       └── AudioTracked/
│           ├── AudioTrackedApp.swift
│           ├── ContentView.swift
│           ├── APIService.swift
│           └── WatermarkView.swift
└── files/                   # Sample audio files
```

## 🔐 Security Considerations

1. **AWS Credentials**: Use IAM roles instead of hardcoded credentials
2. **S3 Bucket**: Consider restricting public access based on your needs
3. **EC2 Security**: Regularly update and patch the instance
4. **HTTPS**: Set up SSL/TLS for production use

## 🚀 Scaling

To scale the application:

1. **Load Balancer**: Use AWS ALB for multiple EC2 instances
2. **Auto Scaling**: Set up Auto Scaling Group for EC2
3. **CDN**: Use CloudFront for static content delivery
4. **Database**: Add RDS for session management if needed

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review AWS CloudWatch logs
3. Ensure all environment variables are set correctly
