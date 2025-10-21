#!/bin/bash

# Fix S3 bucket public access settings
set -e

echo "🔧 Fixing S3 bucket public access settings..."

# Get bucket name from environment or ask user
if [ -z "$S3_BUCKET" ]; then
    read -p "Enter your S3 bucket name: " S3_BUCKET
fi

if [ -z "$S3_BUCKET" ]; then
    echo "❌ No bucket name provided"
    exit 1
fi

echo "Working with bucket: $S3_BUCKET"

# Remove the block public access settings
echo "🔓 Removing block public access settings..."
aws s3api put-public-access-block \
    --bucket $S3_BUCKET \
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

echo "✅ S3 bucket is now configured for public access"
echo "Note: This allows public read access to the watermarked files, which may be desired for your use case."
