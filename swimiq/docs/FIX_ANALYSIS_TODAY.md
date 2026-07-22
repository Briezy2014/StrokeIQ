# FIX ANALYSIS TODAY (read every line)

## What the error means

You saw:

> AI video analysis is temporarily unavailable. Notes-based coaching was saved…

That means:

1. The app called Supabase Edge Function `analyze-swim-video`
2. **That call failed** (usually old **18 MB** server limit, missing deploy, or Gemini key/model)
3. The old app **pretended** it worked by saving a notes-only report

**Uploading the website alone cannot fix this.**  
The **server function** must be redeployed first.

---

## Do these steps in order (do not skip)

### A) Confirm GEMINI_API_KEY (2 minutes)

1. https://supabase.com/dashboard → SwimIQ project  
2. **Project Settings** → **Edge Functions** → **Secrets**  
3. Confirm secret name exactly: `GEMINI_API_KEY`  
4. If missing: add it from https://aistudio.google.com/apikey  

### B) Deploy the fixed server function (10 minutes)

On the PC, after this PR is pulled onto `S:\`:

1. File Explorer → `S:\swimiq\`  
2. Double-click **`DEPLOY-GEMINI-VIDEO.bat`**  
3. Log into Supabase when asked  
4. Wait for **SERVER UPDATE SUCCESS**

This deploys the **100 MB File API** version of `analyze-swim-video`.

### C) Rebuild the Flutter website (15 minutes)

PowerShell:

```powershell
S:
cd swimiq
git pull origin main
powershell -ExecutionPolicy Bypass -File .\scripts\build-web-godaddy.ps1
```

Wait for **DONE**. Open `S:\swimiq\build\web` and confirm `main.dart.js` exists.

### D) Upload to GoDaddy

Upload **everything inside** `S:\swimiq\build\web\` to `public_html` (replace old files).

### E) Test Analyze the right way

1. Open **http://swimiqapp.com** (private window)  
2. Sign in  
3. Video Lab → use a **short** clip first (under 60 seconds if possible)  
4. Tap **Run AI Swim Analysis**  
5. Keep the tab open up to ~2 minutes  

**Success:** coaching report about the actual swim (not “notes-based saved”).  
**Failure:** you will now see a **real** error (size / timeout / key) — not fake success.

---

## If it still fails

| Message | What to do |
|---------|------------|
| too large / 100 MB | Re-export shorter/lower quality clip |
| timed out | Shorter clip; keep tab open |
| GEMINI_API_KEY / not configured | Fix secret in Supabase, redeploy bat |
| function not deployed | Run `DEPLOY-GEMINI-VIDEO.bat` again |
| busy / quota | Wait 2 minutes; check Google AI Studio quota |

---

## What this PR changed in code

- Edge Function: File API path, ~**100 MB** ceiling (replaces 18 MB)  
- App: **no more notes-as-fake-AI-success**  
- Clearer error messages  

Elote (pose metrics + Gemini plan-only) is still the long-term engine (#84).  
**Today’s unblock** is redeploying this Edge Function + rebuilding the site.
