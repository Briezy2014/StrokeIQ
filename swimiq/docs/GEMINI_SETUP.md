# Gemini Video Analysis Setup

SwimIQ Video Lab sends uploaded swim clips to **Google Gemini 2.0 Flash** through a Supabase Edge Function. Your API key stays on the server — never in the Flutter app.

## 1. Add your API key to Supabase (on a computer)

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project  
2. **Project Settings** → **Edge Functions** → **Secrets** (or **Manage secrets**)  
3. Add:

| Name | Value |
|------|--------|
| `GEMINI_API_KEY` | Your key from [Google AI Studio](https://aistudio.google.com/apikey) |

Do **not** commit the key to git or paste it in chat.

## 2. Deploy the Edge Functions

Install the [Supabase CLI](https://supabase.com/docs/guides/cli) on a computer, then:

```bash
cd swimiq
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy analyze-swim-video
supabase functions deploy match-college-recruiting
```

`YOUR_PROJECT_REF` is in Supabase → Project Settings → General → Reference ID.

## 3. Use Video Lab in the app

1. Run the Flutter app (`flutter run`)  
2. Open the **Video** tab  
3. Upload a swim clip (**keep under ~18 MB** for now)  
4. Tap **Analyze** — Gemini watches the video and saves the report  

If the function is not deployed yet, the app falls back to the V1 notes-based report.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `GEMINI_API_KEY is not configured` | Add the secret in Supabase and redeploy the function |
| `Video is too large` | Trim the clip to under ~18 MB |
| `Unauthorized` | Sign in with email/password first |
| Analysis uses notes only | Edge function not deployed — follow step 2 |

## Cost note

Gemini charges per API use. Enable billing on your Google Cloud project linked to AI Studio for production video volume.
