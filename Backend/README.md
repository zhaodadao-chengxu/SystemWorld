# SystemWorld AI Backend

This small local backend keeps the DeepSeek API key off the iOS client.

## Run

```bash
cd Backend
npm start
```

The iOS app calls:

```text
https://systemworld-ai-zhaodadao.onrender.com/api/ai
```

Debug builds also fall back to the local backend:

```text
http://127.0.0.1:8787/api/ai
```

## Deploy to Render

Use the `render.yaml` file in the project root as a Render Blueprint.

Render will ask for `DEEPSEEK_API_KEY` during setup. Put the real key there, not in the iOS app.

After deploy, the expected backend URL is:

```text
https://systemworld-ai-zhaodadao.onrender.com
```
