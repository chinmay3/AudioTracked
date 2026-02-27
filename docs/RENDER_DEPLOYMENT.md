# Render Deployment (Full Functionality)

This deploys the full Flask app (`/` UI + `/api/*`) as one service.

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

## 4. Access URLs

- Website (frontend): `https://<your-render-service>.onrender.com/`
- Health check: `https://<your-render-service>.onrender.com/health`
- API base: `https://<your-render-service>.onrender.com/api`

## 5. iOS app integration

In `ios_frontend/AudioTracked/AudioTracked/APIService.swift`, set:

```swift
private let baseURL = "https://<your-render-service>.onrender.com/api"
```

