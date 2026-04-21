# Vercel Frontend Deployment

This guide is for the fast split setup:
- `frontend/` on Vercel
- Flask API on Render

Do not import the repository root into Vercel for this flow. The root contains a Python `vercel.json` for the Flask app. Set the Vercel project Root Directory to `frontend`.

## 1. Point the frontend at your Render API

Edit [`frontend/config.js`](../frontend/config.js):

```js
window.AUDIOTRACKED_CONFIG = {
    apiBaseUrl: "https://<your-render-service>.onrender.com/api"
};
```

If you later move the backend to a custom domain, update this URL.

## 2. Import the frontend into Vercel

1. Open Vercel and click `Add New...` -> `Project`.
2. Import this repository.
3. In project settings, set `Root Directory` to `frontend`.
4. Framework preset: `Other`.
5. Leave `Build Command`, `Install Command`, and `Output Directory` empty.
6. Deploy.

## 3. Verify

After deploy:
- The homepage should load immediately from Vercel.
- Sample file loading should hit `https://<your-render-service>.onrender.com/api/sample/...`
- Embed and extract responses should return working download and preview links.

## 4. Optional custom domain

1. Open the Vercel project.
2. Go to `Settings` -> `Domains`.
3. Add your domain.
4. Update DNS as instructed by Vercel.

## Notes

- Vercel hosts only the static frontend in this setup.
- The frontend already normalizes relative URLs returned by the backend.
- If `frontend/config.js` is left empty, the site falls back to same-origin `/api`, which is useful for local or single-host deployments but not for Vercel + Render.
