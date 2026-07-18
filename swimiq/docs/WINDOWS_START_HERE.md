# Windows — Start SwimIQ (Elite Video Lab)

Use the folder: `Desktop\StrokeIQ`  
(not `StrokeIQ-Elite`).

## Every launch (recommended)

1. Double-click:

   `Desktop\StrokeIQ\START-SWIMIQ-WITH-ELITE.bat`

2. Keep **both** windows open:
   - Elite analysis server (`Uvicorn running on http://127.0.0.1:8080`)
   - SwimIQ Chrome launch window

3. Sign in → **Elite** tab → green **Elite server connected** → **Confirm & Analyze**

That one bat:
- updates the branch
- starts the Elite server if needed
- waits until `http://127.0.0.1:8080/health` works
- then launches Chrome

## Health check

Open: http://127.0.0.1:8080/health

You want `"ffmpeg_available":true`. If false, run `RESTART-ELITE-AFTER-FFMPEG.bat` after installing FFmpeg.

## `.env` (Flutter)

In `swimiq\.env`:

```env
SUPABASE_URL=https://YOURPROJECT.supabase.co
SUPABASE_ANON_KEY=eyJ...your_anon_key...
ANALYSIS_API_BASE_URL=http://127.0.0.1:8080
VIDEO_ENGINE_V2=true
VIDEO_ENGINE_V2_ALLOWLIST=
VIDEO_ENGINE_V2_DUAL_RUN=false
```

Use `127.0.0.1` (not `localhost`) so Windows IPv6 does not miss the server.

## Accounts

| Role | Login / code |
|------|----------------|
| Master | `briezy682014@gmail.com` |
| Demo | `demo@swimiqapp.com` / `SwimIQ` |
| Coach | Redeem `COACH-EVAL-14` (or `COACH-TRIAL-30`) in Settings → Plans |

## If Chrome says Failed to fetch / server not ready

The Elite server window is closed or crashed. Run `START-SWIMIQ-WITH-ELITE.bat` again and leave the Elite window open.
