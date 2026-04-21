# Render Backend Deployment

This deploys the Flask backend on Render. Pair it with the Vercel frontend in [`docs/VERCEL_DEPLOYMENT.md`](VERCEL_DEPLOYMENT.md) if you want the website to load fast without waiting for a Render page wake-up.

## 1. Push code to GitHub

Render deploys from a Git repository.

## 2. Create service on Render

1. Open Render dashboard.
2. Click `New +` -> `Blueprint`.
3. Select your repository.
4. Render will detect `render.yaml`.
5. Create the service.

## 3. Environment configuration

Default `render.yaml` sets:
- `DISABLE_S3=1`
- `AWS_REGION=us-east-1`

With `DISABLE_S3=1`, app still works, but generated files live on ephemeral disk.

For persistent download links, set:
- `DISABLE_S3=0`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `S3_BUCKET`
- `AWS_REGION`

Optional:
- `PUBLIC_BASE_URL=https://<your-render-service>.onrender.com`

`PUBLIC_BASE_URL` is useful if you want backend-generated local file links to always use the public backend host explicitly.

## 4. Access URLs

- Backend root UI: `https://<your-render-service>.onrender.com/`
- Health check: `https://<your-render-service>.onrender.com/health`
- API base: `https://<your-render-service>.onrender.com/api`
- Static frontend on Vercel: separate project, usually `https://<your-vercel-project>.vercel.app/`

## 5. iOS app integration

In `ios_frontend/AudioTracked/AudioTracked/APIService.swift`, set:

```swift
private let baseURL = "https://<your-render-service>.onrender.com/api"
```

## 6. Important behavior on Render free instances

- Render free web services spin down after inactivity.
- The first API request after idle can still be slow while the backend wakes up.
- Moving the frontend to Vercel fixes the slow page load, but not free-tier backend cold starts.
