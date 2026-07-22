# Gemini Video Analysis Setup

SwimIQ Video Lab sends uploaded swim clips to **Google Gemini** through a Supabase Edge Function. Your API key stays on the server — never in the Flutter app.

**Phone clips:** after deploying the current function, analysis accepts files up to about **100 MB** (File API). Prefer clips **under 2 minutes**.

## 1. Add your API key to Supabase

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project  
2. **Project Settings** → **Edge Functions** → **Secrets**  
3. Add:

| Name | Value |
|------|--------|
| `GEMINI_API_KEY` | Your key from [Google AI Studio](https://aistudio.google.com/apikey) |

Do **not** commit the key to git or paste it in chat.

## 2. Deploy the Edge Function (Windows)

**Easiest:** double-click `swimiq\DEPLOY-GEMINI-VIDEO.bat`

Or with Supabase CLI:

```bash
cd swimiq
npx --yes supabase login
npx --yes supabase link --project-ref bryurwyeosbffvfpdpbv
npx --yes supabase functions deploy analyze-swim-video
```

## 3. Rebuild + upload the website

Server deploy alone is not enough if GoDaddy still has an old Flutter build:

```powershell
S:
cd swimiq
powershell -ExecutionPolicy Bypass -File .\scripts\build-web-godaddy.ps1
```

Upload **all** of `build\web` to GoDaddy `public_html`.

## 4. Test

1. Open Video Lab  
2. Upload a short swim clip  
3. Tap **Analyze** — wait up to ~2 minutes with the tab open  

Full checklist: **[FIX_ANALYSIS_TODAY.md](FIX_ANALYSIS_TODAY.md)**

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `GEMINI_API_KEY is not configured` | Add the secret, redeploy the function |
| `Video is too large` / 413 | Redeploy current function; or trim clip under ~100 MB |
| `Unauthorized` | Sign in again |
| Notes-based / temporarily unavailable | Old server or old website — do steps 2 and 3 again |

## Cost note

Gemini charges per API use. Enable billing on the Google Cloud project linked to AI Studio for production volume.
