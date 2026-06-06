# SystemWorld Cloudflare Worker

This is the no-card backend option for SystemWorld.

## Required secret

Set this in Cloudflare Workers:

```text
ARK_API_KEY
```

## Routes

```text
GET /health
POST /api/ai
```

The iOS app should call:

```text
https://systemworld-ai-zhaodadao.420987231.workers.dev/api/ai
```
