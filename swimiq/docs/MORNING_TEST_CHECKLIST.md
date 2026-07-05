# SwimIQ Morning Test Checklist

Use this after pulling the latest code from PR #25 (`cursor/passport-nav-standards-8d23`).

---

## Step 0 — Pull latest code (Windows)

Open **PowerShell** and run these in order:

```powershell
subst F: "C:\Users\Kara Williams\flutter"
subst S: "C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ"
$env:Path = "F:\bin;" + $env:Path
cd S:\swimiq
git fetch origin
git merge origin/cursor/passport-nav-standards-8d23
flutter pub get
```

If merge conflicts appear, stop and ask for help before continuing.

---

## Step 1 — Confirm `.env` file

File must be here (not in `assets/`):

`S:\swimiq\.env`

Contents (no `/rest/v1/` on the URL):

```
SUPABASE_URL=https://bryurwyeosbffvfpdpbv.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

---

## Step 2 — Start the app in Chrome

```powershell
cd S:\swimiq
$env:Path = "F:\bin;" + $env:Path
flutter run -d chrome
```

Wait until Chrome opens and the login screen appears.

**Login screen check:** One logo, tagline *Built in the Water. Driven by Possibility.*, then "Welcome back".

---

## Step 3 — Sign in

Use your email and password. You should land on the **Dashboard** tab.

**Bottom nav should show 6 tabs only:**
Dashboard · PBs · Log · Goals · Meets · Passport

There should be **no Video tab** and **no Add tab**.

---

## Step 4 — Athlete Passport (most important)

1. Tap **Passport** tab
2. Scroll to **Edit Athlete Passport**
3. Tap **Date of Birth** → pick birthday
4. Tap **Girls** or **Boys**
5. Tap **Save Athlete Passport**
6. Confirm the orange "USA cuts need birthday and gender" banner disappears
7. Confirm **Athlete Identity** shows birthday and gender

### Passport hub modules (each opens a different screen)

| Module | What it should do |
|--------|-------------------|
| **AI Coach** | Short list of what to fix in practice |
| **Video Lab** | Upload video + full Gemini/MediaPipe analysis |
| **Race Intelligence™** | Meet-day strategy and race plans |
| **USA Standards** | Search standards table (no red error screen) |

---

## Step 5 — Log a training session

1. Tap **Log** tab
2. Tap the blue **Log Session** button (bottom right)
3. Fill in stroke, distance, time, course
4. Tap **Save Swim Session**
5. You should return to the Log list with your new session
6. Tap **⋮** on a session → **Edit** or **Delete** to confirm edit works

---

## Step 6 — Goals and Meets

### Goals tab
1. Add a goal (stroke, distance, target time, date)
2. Tap **⋮** on the goal → **Edit** → change time → Save
3. Confirm the update appears

### Meets tab
1. Add a meet result
2. Tap **⋮** → **Edit** → Save
3. Confirm it updates

---

## Step 7 — USA Standards

1. Passport → **USA Standards**
2. Screen should load (no red "No Material widget" error)
3. Search for an event (e.g. "50 Butterfly")
4. Filter by age group and gender

---

## Step 8 — Video Lab + Gemini + MediaPipe

### Before testing video (one-time Supabase setup)

Gemini requires the edge function deployed with your API key. If you have not done this yet:

1. Get a Gemini API key from Google AI Studio
2. In Supabase dashboard → Project Settings → Edge Functions → Secrets:
   - Add `GEMINI_API_KEY`
3. Deploy the function (from a machine with Supabase CLI):
   ```bash
   supabase functions deploy analyze-swim-video
   ```

### Test video analysis

1. Passport → **Video Lab**
2. Upload a **short MP4** (under ~18 MB, swimmer visible in frame)
3. Add race notes (start, breakout, breathing, finish)
4. Tap **Run Full Analysis (Gemini + MediaPipe)**
5. Wait (first run may take 1–2 minutes while pose models load)

**Success looks like:**
- Snackbar says **"Gemini + MediaPipe analysis saved"** or **"Gemini analysis saved"**
- Video card shows **Engine: swimiq-v2-gemini** or **swimiq-v2-gemini-mediapipe**
- Coaching sections appear below the video
- Pose metrics section may appear if body was detected

**If Gemini is not deployed yet:**
- Snackbar warns about notes-based fallback
- Card shows red text: *"Gemini was not used"*

6. Go to **AI Coach** — should show top corrections from the analysis
7. Go to **Race Intelligence™** — should show meet-day tips and race plans

---

## Step 9 — Settings

1. Tap gear icon (top right)
2. Tap **Edit Athlete Passport** → should jump to Passport tab
3. Confirm your email and display name show correctly

---

## Step 10 — Quick connectivity check

| Action | Should update |
|--------|----------------|
| Log a session | Dashboard, PBs, Training Log |
| Save passport birthday/gender | USA Standards cuts, orange banner |
| Add goal | Race Intelligence race plans |
| Video analysis | AI Coach priorities |

Pull down to refresh on any tab if data looks stale.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Supabase is not configured" | Fix `.env` location and URL format |
| Red screen on USA Standards | Pull latest code (Scaffold fix) |
| Gemini not working | Deploy edge function + set `GEMINI_API_KEY` |
| Pose metrics missing | Use Chrome web; swimmer body must be visible; try MP4 |
| Path errors on build | Use `subst F:` and `subst S:` commands above |
| Old UI (8 tabs, triple logo) | `git pull` did not complete — re-run Step 0 |

---

## When everything passes

You are ready for full testing with Aspyn's profile:
- Complete passport (birthday, gender, graduation year, photo)
- Log real training sessions
- Upload a race video and run full analysis
- Check USA motivational cuts for her age group
