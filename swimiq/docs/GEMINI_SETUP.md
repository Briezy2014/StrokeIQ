# Gemini Video Analysis Setup

SwimIQ Video Lab sends uploaded swim clips to **Google Gemini 2.0 Flash** through a Supabase Edge Function. Your API key stays on the server — never in the Flutter app.

## How to get your Gemini API key (step by step)

Think of the API key like a **password that lets your Supabase server talk to Google’s AI**. You create it once in Google, paste it once into Supabase, and SwimIQ uses it when someone taps **Analyze** on a video.

### Part A — Create the key in Google AI Studio

1. On a computer, open **[Google AI Studio → API keys](https://aistudio.google.com/apikey)**  
2. Sign in with a **Google account you control** (your Gmail is fine — e.g. `briezy682014@gmail.com`).  
3. The first time, Google may ask you to accept terms — click **Agree** or **Continue**.  
4. On the API keys page, click **Create API key** (or **Get API key**).  
5. If it asks which Google Cloud project to use:
   - Choose **Create API key in new project** (easiest), **or**
   - Pick an existing project if you already have one for SwimIQ.  
6. Google shows a long string starting with something like `AIza...` — that is your key.  
7. Click **Copy** and paste it into a **private note** (Notes app, password manager) for a moment — you’ll need it in Part B.  
   - **Do not** post this key in email, Google Groups, GitHub, or chat.  
   - **Do not** put it inside the Flutter app code.

**If you don’t see “Create API key”:** make sure you’re signed into the right Google account and try Chrome. Some school/work Google accounts block API access — use a personal Gmail if that happens.

**Cost:** Google gives free tier usage for development. For lots of tester videos, you may need billing on the linked Google Cloud project later (see Cost note at the bottom).

### Part B — Paste the key into Supabase

1. Open **[Supabase Dashboard](https://supabase.com/dashboard)** → your SwimIQ project.  
2. Go to **Project Settings** (gear icon) → **Edge Functions** → **Secrets** (sometimes labeled **Manage secrets**).  
3. Click **Add new secret** (or **New secret**).  
4. Enter exactly:

| Name | Value |
|------|--------|
| `GEMINI_API_KEY` | Paste the `AIza...` key you copied from Google |

5. Save. The name must be **`GEMINI_API_KEY`** — spelling and capitals matter.

You’re done with the key. Next: deploy the edge function (Part C below) so the server actually uses it.

---

## 1. Add your API key to Supabase (summary)

If you already completed Part A and Part B above, skip to **Part C — Deploy**.

| Name | Value |
|------|--------|
| `GEMINI_API_KEY` | Your key from [Google AI Studio](https://aistudio.google.com/apikey) |

Do **not** commit the key to git or paste it in chat.

## 2. Deploy the Edge Functions (required — Part C)

**If you see "Video is too large for Gemini inline analysis (max ~18 MB)"**, your server is running an old build. Redeploy `analyze-swim-video` — the current version supports clips up to **~100 MB** via the Gemini File API.

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
3. Upload a swim clip (up to **~100 MB**)  
4. Tap **Analyze** — Gemini watches the video and saves the report  

Clips under ~18 MB use fast inline upload. Larger clips (18–100 MB) are sent through the **Gemini File API** automatically — no trimming required unless the file exceeds 100 MB.

If the function is not deployed yet, the app falls back to the V1 notes-based report.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `GEMINI_API_KEY is not configured` | Add the secret in Supabase and redeploy the function |
| `Video is too large` | Trim the clip to under ~100 MB |
| `timed out` | Use a shorter clip (under ~60 seconds works best) |
| `Unauthorized` | Sign in with email/password first |
| Analysis uses notes only | Edge function not deployed — follow step 2 |

## Cost note

Gemini charges per API use. Enable billing on your Google Cloud project linked to AI Studio for production video volume.
