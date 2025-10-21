#!/bin/bash

echo "🌐 Setting up proper domain hosting for AudioTracked"
echo "=================================================="

# Get current EC2 public IP
EC2_IP="54.204.110.168"
echo "📍 Current EC2 IP: $EC2_IP"

echo ""
echo "🎯 Domain Setup Options:"
echo "1. Free Domain (.tk, .ml, .ga) - FREE"
echo "2. Custom Domain ($10-15/year) - Professional"
echo "3. GitHub Pages + Custom Domain - FREE hosting"
echo "4. Vercel/Netlify - FREE with custom domain"

echo ""
echo "📋 Steps for FREE Domain Setup:"
echo "1. Go to https://www.freenom.com"
echo "2. Search for: audiotracked.tk (or similar)"
echo "3. Register the domain (FREE for 1 year)"
echo "4. Point DNS to: $EC2_IP"
echo "5. Set up Cloudflare for SSL (FREE)"

echo ""
echo "🔧 Quick Setup Commands:"
echo "# Install nginx for reverse proxy"
echo "sudo apt update && sudo apt install nginx -y"

echo ""
echo "# Configure nginx"
echo "sudo nano /etc/nginx/sites-available/audiotracked"

echo ""
echo "📝 Nginx Configuration:"
cat << 'EOF'
server {
    listen 80;
    server_name your-domain.tk www.your-domain.tk;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo ""
echo "🔒 SSL Setup with Let's Encrypt:"
echo "sudo apt install certbot python3-certbot-nginx -y"
echo "sudo certbot --nginx -d your-domain.tk -d www.your-domain.tk"

echo ""
echo "✅ After domain setup, your site will be accessible at:"
echo "🌐 https://your-domain.tk"
echo "🌐 https://www.your-domain.tk"
