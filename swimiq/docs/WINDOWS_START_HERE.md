# Windows — Start SwimIQ (Elite Video Lab)

Use this on the **Kara Williams** Windows PC.

## One-time folder setup

1. Use the clean clone folder: `Desktop\StrokeIQ-Elite`
2. In File Explorer open: `StrokeIQ-Elite\swimiq\scripts`
3. Double-click `setup-short-path.bat` (creates drive `S:`)

## Every time you want the app

### A) Make sure `.env` exists

In File Explorer open `StrokeIQ-Elite\swimiq` and double-click:

`make-env.bat`

Put real Supabase values:

```env
SUPABASE_URL=https://YOURPROJECT.supabase.co
SUPABASE_ANON_KEY=eyJ...your_anon_key...
ANALYSIS_API_BASE_URL=http://localhost:8080
VIDEO_ENGINE_V2=true
VIDEO_ENGINE_V2_ALLOWLIST=
VIDEO_ENGINE_V2_DUAL_RUN=false
```

Save and close Notepad.

### B) Launch

Double-click:

`START-SWIMIQ.bat`

Or in PowerShell:

```powershell
S:
cd swimiq
.\START-SWIMIQ.bat
```

### C) What “good” looks like

In the black/PowerShell window you must see:

1. `[OK] .env looks usable`
2. `Got dependencies!` ← this is only halfway
3. `Starting Chrome NOW with dart-defines...`
4. `Launching lib\main.dart on Chrome...`
5. Browser shows **login**, not the gray gear

Then sign in as `briezy682014@gmail.com` → Video tab → **Elite Video Lab**

## Important

- `Got dependencies!` alone means packages installed. It is **not** the app.
- Do **not** run only `flutter pub get`.
- Do **not** run plain `flutter run -d chrome` without the launcher (keys won’t load on web).
- Ignore “31 packages have newer versions…” — that is a notice, not a failure.

## Accounts

| Role | Login / code |
|------|----------------|
| Master | `briezy682014@gmail.com` |
| Demo | `demo@swimiqapp.com` / `SwimIQ` |
| Coach | Redeem `COACH-EVAL-14` (or `COACH-TRIAL-30`) in Settings → Plans |
