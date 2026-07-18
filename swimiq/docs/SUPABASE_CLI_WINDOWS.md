# Supabase CLI on Windows (Kara)

## You probably do NOT need this right now

| Goal | Need `supabase login`? |
|------|------------------------|
| **Run SwimIQ in Chrome** | **No** — use `KARA-CLICK-THIS.bat` |
| **Sign in / training log / passport** | **No** — only needs `.env` with Supabase URL + anon key |
| **Deploy AI video analysis (Gemini)** | **Yes** — one-time setup on a computer |
| **Deploy Stripe billing** | **Yes** — one-time setup |

If PowerShell says `supabase is not recognized`, the CLI is simply **not installed**. That is normal on a fresh Windows laptop.

---

## Easiest install (if you have Node.js)

In PowerShell from `S:\swimiq` (or `C:\SwimIQWork\swimiq` after running `FIX-KARA-PATHS.bat`):

```powershell
node --version
```

If you see `v20` or higher:

```powershell
cd S:\swimiq
npm install supabase --save-dev
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase functions deploy analyze-swim-video
```

Replace `YOUR_PROJECT_REF` with the **Reference ID** from Supabase Dashboard → Project Settings → General.

> **Do not** run `npm install -g supabase` — Supabase no longer supports global npm install on Windows.

---

## Install with Scoop (recommended if you do not have Node)

1. Open **PowerShell as Administrator**
2. Run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
iwr -useb get.scoop.sh | iex
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

3. Close PowerShell, open a **new** window, then:

```powershell
supabase --version
supabase login
```

---

## Skip the CLI entirely (Gemini API key only)

You can add secrets in the **browser** without installing anything:

1. [Supabase Dashboard](https://supabase.com/dashboard) → your project
2. **Project Settings** → **Edge Functions** → **Secrets**
3. Add `GEMINI_API_KEY` = your key from [Google AI Studio](https://aistudio.google.com/apikey)

You still need someone with the CLI to run `supabase functions deploy analyze-swim-video` once — or ask Cursor/tech help to deploy from GitHub.

---

## Still stuck?

For **launching the app**, ignore Supabase CLI and use:

1. `FIX-KARA-PATHS.bat` (once)
2. `KARA-CLICK-THIS.bat`

See [WINDOWS_SETUP.md](WINDOWS_SETUP.md).
