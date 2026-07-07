# SwimIQ Flutter App

Cross-platform swim performance tracker for **Android** and **iOS**, connected to the same Supabase backend as the Streamlit reference app.

## Version 1 — Complete

| Feature | Status |
|---------|--------|
| Splash + email/password auth | Done |
| Dashboard with SwimIQ Score + chart | Done |
| Training log (list, edit, delete) | Done |
| Add swim session + PB detection | Done |
| Personal bests | Done |
| Goals with progress + edit/delete | Done |
| Meet results + edit/delete | Done |
| Athlete passport (swimmer profile) | Done |
| Video Lab + Gemini AI video analysis | Done — [deploy setup](docs/GEMINI_SETUP.md) |
| Settings (account, sign out) | Done |
| Auto-link auth user to swimmer profile | Done |

## Setup

> **Note:** The Streamlit app (`app.py` on port 8501) is separate from this Flutter app.
> Running Streamlit will **not** show Flutter changes.

### Windows (paths with spaces in your username)

If your folder is under `C:\Users\Kara Williams\...`, Flutter may fail with
`'C:\Users\Kara' is not recognized`. See **[docs/WINDOWS_SETUP.md](docs/WINDOWS_SETUP.md)**.

Quick start after running `scripts\setup-short-path.bat`:

```powershell
S:
cd swimiq
.\run-chrome.ps1
```

See **[docs/TESTFLIGHT.md](docs/TESTFLIGHT.md)** for inviting parents via **TestFlight** (iOS beta).

### Everyone else

```bash
cd swimiq
flutter pub get
cp .env.example .env   # add SUPABASE_URL and SUPABASE_ANON_KEY
flutter run -d chrome
```

Enable **Email** auth in Supabase Dashboard → Authentication → Providers.

### Gemini video analysis

Add `GEMINI_API_KEY` to Supabase Edge Function secrets and deploy `analyze-swim-video`.  
See **[docs/GEMINI_SETUP.md](docs/GEMINI_SETUP.md)** for step-by-step instructions.

Pose metrics (MediaPipe-compatible BlazePose) run in **Flutter web (Chrome)**.  
See **[docs/POSE_AND_GEMINI.md](docs/POSE_AND_GEMINI.md)**.

## Test

```bash
cd swimiq
flutter test
flutter analyze
```

## Database schema

No schema changes for V1. Auth uses `auth.users`. Swimmer data uses existing tables with `swimmer` / `swimmer_name` keys linked from the authenticated user's display name.

## Reference

The Streamlit app (`app.py` in repo root) remains unchanged.
