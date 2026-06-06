# SystemWorld Render Backend

This is the optional Render version of the backend. The live app currently uses the Cloudflare Worker backend because it does not require adding a payment card.

## Run

```bash
cd Backend
npm start
```

The live iOS app calls the Cloudflare Worker URL documented in `CloudflareWorker/README.md`.

If you choose to use Render later, point the iOS app to:

```text
https://systemworld-ai-zhaodadao.onrender.com/api/ai
```

Debug builds also fall back to the local backend:

```text
http://127.0.0.1:8787/api/ai
```

## Deploy to Render

Use the `render.yaml` file in the project root as a Render Blueprint.

Render will ask for `ARK_API_KEY` during setup. Put the real Volcengine Ark key there, not in the iOS app.

After deploy, the expected backend URL is:

```text
https://systemworld-ai-zhaodadao.onrender.com
```
