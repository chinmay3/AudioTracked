# 🚀 Vercel Deployment Guide for AudioTracked

## Quick Deploy to Vercel

### Option 1: Deploy via Vercel CLI (Recommended)

1. **Install Vercel CLI**:
   ```bash
   npm i -g vercel
   ```

2. **Login to Vercel**:
   ```bash
   vercel login
   ```

3. **Deploy from project directory**:
   ```bash
   vercel
   ```

4. **Follow the prompts**:
   - Set up and deploy? **Y**
   - Which scope? **Your account**
   - Link to existing project? **N**
   - Project name: **audiotracked**
   - Directory: **./** (current directory)
   - Override settings? **N**

### Option 2: Deploy via GitHub Integration

1. **Go to [vercel.com](https://vercel.com)**
2. **Sign up/Login with GitHub**
3. **Click "New Project"**
4. **Import your repository**: `chinmay3/AudioTracked`
5. **Configure settings**:
   - Framework Preset: **Other**
   - Build Command: `echo "No build needed"`
   - Output Directory: `public`
   - Install Command: `pip install -r requirements.txt`
6. **Click "Deploy"**

## Environment Variables

After deployment, add these environment variables in Vercel dashboard:

```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
S3_BUCKET=your_bucket_name
```

## Project Structure

```
AudioTracked/
├── app.py              # Flask API server
├── vercel.json         # Vercel configuration
├── requirements.txt    # Python dependencies
├── public/
│   └── index.html      # Landing page
├── ios_frontend/       # SwiftUI app
└── ... (other files)
```

## Features

- ✅ **Automatic HTTPS**: SSL certificate included
- ✅ **Global CDN**: Fast loading worldwide
- ✅ **Custom Domain**: Add your own domain
- ✅ **Environment Variables**: Secure credential storage
- ✅ **Auto Deploy**: Deploys on every git push

## URLs After Deployment

- **Main Site**: `https://audiotracked.vercel.app`
- **API Endpoints**: `https://audiotracked.vercel.app/api/`
- **Health Check**: `https://audiotracked.vercel.app/health`

## Troubleshooting

### If deployment fails:
1. Check that all dependencies are in `requirements.txt`
2. Ensure `vercel.json` is properly configured
3. Check Vercel logs in dashboard

### If API doesn't work:
1. Verify environment variables are set
2. Check AWS credentials are correct
3. Ensure S3 bucket exists and is accessible

## Custom Domain (Optional)

1. **Buy a domain** (GoDaddy, Namecheap, etc.)
2. **In Vercel dashboard**:
   - Go to Project Settings
   - Click "Domains"
   - Add your domain
3. **Update DNS**:
   - Add CNAME record: `www` → `cname.vercel-dns.com`
   - Add A record: `@` → Vercel IP

## Support

- **Vercel Docs**: https://vercel.com/docs
- **Flask on Vercel**: https://vercel.com/guides/deploying-flask-to-vercel
