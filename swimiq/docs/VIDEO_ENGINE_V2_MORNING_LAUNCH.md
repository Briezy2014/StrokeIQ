# Elite Video Lab — Start From Zero (Do Every Step)

You have not done anything yet. Follow this top to bottom.

**What you are building toward:**  
Open SwimIQ → sign in → Video tab says **Elite Video Lab** → upload a swim video → tap **Run Elite Analysis** → see progress → see results.

**Your first-launch email:** `aspyn682014@yahoo.com`

---

# PART 0 — Get ready (software + code)

## 0.1 Accounts you need open in a browser

1. Supabase: https://supabase.com/dashboard (your SwimIQ project)
2. Google AI Studio (for Gemini): https://aistudio.google.com/apikey
3. GitHub (optional, if you get code from there): https://github.com/Briezy2014/StrokeIQ

## 0.2 Software that must already be installed on your computer

- **Git**
- **Flutter** (`flutter --version` works in Terminal / PowerShell)
- **Python 3** (`python3 --version` or `python --version`)
- **ffmpeg** (`ffmpeg -version`) — used by the analysis server

If any of those fail, install that tool first, then come back.

## 0.3 Get the Elite Video Lab code on your computer

Open Terminal (Mac) or PowerShell (Windows).

If you do **not** already have the StrokeIQ folder:

```bash
cd ~
git clone https://github.com/Briezy2014/StrokeIQ.git
cd StrokeIQ
```

If you **already** have the folder:

```bash
cd ~/StrokeIQ
```

(Use your real path if the folder lives somewhere else, for example `Documents\StrokeIQ` on Windows.)

Then download the Elite Video Lab branch:

```bash
git fetch origin
git checkout cursor/elote-m9-flutter-supabase-b7ef
git pull origin cursor/elote-m9-flutter-supabase-b7ef
```

You should now see this file on disk:

`swimiq/docs/VIDEO_ENGINE_V2_MORNING_LAUNCH.md`

---

# PART A — Update Supabase (browser only)

**What this does:** Creates Elite Video Lab database tables and makes uploaded videos private.

## A1. Open SQL Editor

1. Go to https://supabase.com/dashboard
2. Sign in
3. Click your SwimIQ project
4. Left sidebar → **SQL Editor**
5. Click **New query**

## A2. Run file 005

1. On your computer, open:

   `StrokeIQ/swimiq/supabase/migrations/005_video_analysis_engine_v2.sql`

2. Select all → Copy
3. Paste into the Supabase SQL box
4. Click **Run**
5. Wait for success (errors about “already exists” are usually OK)

## A3. Run file 006

1. Click **New query**
2. Open / copy:

   `StrokeIQ/swimiq/supabase/migrations/006_swim_videos_private_storage.sql`

3. Paste → **Run** → wait for success

## A4. Run file 007

1. Click **New query**
2. Open / copy:

   `StrokeIQ/swimiq/supabase/migrations/007_drop_legacy_open_video_policies.sql`

3. Paste → **Run** → wait for success

## A5. Verify

1. **New query**
2. Paste this:

```sql
SELECT policyname
FROM pg_policies
WHERE tablename IN ('swim_videos', 'swim_video_analyses')
ORDER BY tablename, policyname;
```

3. **Run**
4. Confirm you do **not** see `swim_videos_all` or `swim_video_analyses_all`

**Part A is done.**

---

# PART B — Start the analysis server

**What this does:** Runs the Python “brain” that measures videos. SwimIQ talks to it at `http://localhost:8080`.

Keep one Terminal/PowerShell window open for this server the whole time you test.

## B1. Copy keys from Supabase

1. Supabase project → gear **Project Settings** (bottom left)
2. Click **API**
3. Copy into a notes app:
   - **Project URL** → example `https://abcd1234.supabase.co`
   - **anon public** key
   - **service_role** key (secret — never put this in the Flutter app)

## B2. Create a Gemini API key

1. Go to https://aistudio.google.com/apikey
2. Sign in with Google
3. **Create API key**
4. Copy it into your notes app

## B3. Create `services/video_analysis/.env`

In Terminal / PowerShell:

**Mac / Git Bash:**

```bash
cd ~/StrokeIQ/services/video_analysis
cp .env.example .env
```

**Windows PowerShell:**

```powershell
cd ~\StrokeIQ\services\video_analysis
copy .env.example .env
```

Open the new `.env` file in Cursor / VS Code / Notepad.

Change these lines to your real values (leave other lines alone for now):

```env
POSE_ENABLED=true
GEMINI_REPORT_ENABLED=true
GEMINI_API_KEY=paste_your_gemini_key_here
SUPABASE_URL=https://abcd1234.supabase.co
SUPABASE_ANON_KEY=paste_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=paste_service_role_key_here
SUPABASE_AUTH_REQUIRED=true
SUPABASE_PERSIST_RESULTS=true
VIDEO_ENGINE_V2_ALLOWLIST=aspyn682014@yahoo.com
CORS_ALLOW_ORIGINS=*
```

Save the file.

## B4. Activate Python and install packages (first time)

**Mac:**

```bash
cd ~/StrokeIQ/services/video_analysis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**Windows PowerShell:**

```powershell
cd ~\StrokeIQ\services\video_analysis
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

If pose models were never downloaded on this computer, also run (still inside the activated venv):

```bash
python scripts/download_rtmdet.py
python scripts/download_rtmpose.py
```

(If those scripts error, tell me the exact error — do not skip forever; Elite metrics need them.)

## B5. Start the server

Still in `services/video_analysis`, with venv activated:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

You should see something like `Uvicorn running on http://0.0.0.0:8080`.

**Leave this window open.** Do not close it.

## B6. Prove the server is alive

Open a **second** Terminal / PowerShell window:

```bash
curl -s http://localhost:8080/health
```

Windows without curl can use the browser instead: open http://localhost:8080/health

You want a healthy JSON response, not “connection refused”.

**Part B is done** when that health page/response works.

---

# PART C — Turn Elite Video Lab on in SwimIQ (the app)

**What this does:** Tells the Flutter SwimIQ app:

1. which Supabase project to use  
2. where the analysis server is (`ANALYSIS_API_BASE_URL`)  
3. that Elite Video Lab is ON for your email only  

## C1. Create / open the Flutter settings file

The file you must edit is:

`StrokeIQ/swimiq/.env`

**Mac:**

```bash
cd ~/StrokeIQ/swimiq
cp .env.example .env
```

**Windows PowerShell:**

```powershell
cd ~\StrokeIQ\swimiq
copy .env.example .env
```

Open `swimiq/.env` in an editor.

## C2. Put exactly these kinds of values in `swimiq/.env`

Replace the placeholder values with yours. Use the **same** Supabase Project URL and **anon** key from Part B1.

```env
SUPABASE_URL=https://abcd1234.supabase.co
SUPABASE_ANON_KEY=paste_anon_key_here

ANALYSIS_API_BASE_URL=http://localhost:8080
VIDEO_ENGINE_V2=true
VIDEO_ENGINE_V2_ALLOWLIST=aspyn682014@yahoo.com
VIDEO_ENGINE_V2_DUAL_RUN=false
```

### What each line means

| Line | Meaning |
|------|---------|
| `SUPABASE_URL` | Your Supabase project address |
| `SUPABASE_ANON_KEY` | Public app key (safe in Flutter) |
| `ANALYSIS_API_BASE_URL` | Where the Part B server is running |
| `VIDEO_ENGINE_V2=true` | Turn Elite Video Lab on |
| `VIDEO_ENGINE_V2_ALLOWLIST=...` | Only this email sees Elite (your email) |
| `VIDEO_ENGINE_V2_DUAL_RUN=false` | Hide the old “legacy analysis” extra button for now |

### Critical rules for Part C

- **DO** put `SUPABASE_URL` and `SUPABASE_ANON_KEY` here  
- **DO NOT** put `SUPABASE_SERVICE_ROLE_KEY` here  
- **DO NOT** put `GEMINI_API_KEY` here  
- Those two secrets stay only in `services/video_analysis/.env` from Part B  

### If you test on a real phone (not Chrome / simulator)

1. Keep the Part B server running on your computer  
2. Put phone and computer on the **same Wi‑Fi**  
3. Find your computer’s IP:
   - Mac Terminal: `ipconfig getifaddr en0`
   - Windows PowerShell: `ipconfig` (look for IPv4 Address)
4. Change Flutter env to:

```env
ANALYSIS_API_BASE_URL=http://192.168.x.x:8080
```

(Use your real IP, not the letters.)

For **Chrome on the same computer** as the server, `http://localhost:8080` is correct.

Save `swimiq/.env`.

## C3. Install Flutter packages

```bash
cd ~/StrokeIQ/swimiq
flutter pub get
```

## C4. Start SwimIQ

**Easiest first test (Chrome on the same computer as Part B):**

```bash
cd ~/StrokeIQ/swimiq
flutter run -d chrome
```

**Or pick a device** from `flutter devices`, then:

```bash
flutter run -d <device_id>
```

Wait until the app window/browser opens.

## C5. Sign in and open Elite Video Lab

1. Sign in with email **`aspyn682014@yahoo.com`** and your password  
2. At the bottom navigation, tap **Video**  
3. At the top of that screen, the title must say **Elite Video Lab**  
   - If it still says only **Video Lab**, Elite is not on for this account/env — recheck C2 and restart the app  
4. Upload a short swim video (MP4)  
5. Tap **Run Elite Analysis**  
6. Fill stroke / distance / course if asked → confirm  
7. Wait on the progress screen  
8. Open results when finished  

## C6. Success checklist

You are done when all of these are true:

- [ ] Part B health URL still works  
- [ ] Video tab title = **Elite Video Lab**  
- [ ] Upload works  
- [ ] **Run Elite Analysis** opens setup (not the old silent path)  
- [ ] Progress screen moves through stages  
- [ ] Results screen shows metrics as numbers or “Unavailable” (not fake zeros)  
- [ ] Coaching text may be missing if Gemini fails; metrics should still show  

---

# If something goes wrong

| Problem | What to do |
|---------|------------|
| Title is still **Video Lab** | Confirm `.env` has `VIDEO_ENGINE_V2=true`, allowlist email matches sign-in, fully restart `flutter run` |
| “Connection refused” / can’t reach API | Part B server not running, or phone needs computer IP instead of localhost |
| Analysis forbidden / not enabled | Allowlist email mismatch between Flutter `.env`, backend `.env`, and the account you signed in with |
| Upload works but playback blank | Normal until signed URL works; try a newly uploaded clip after Part A migrations |
| Want old Video Lab back immediately | In `swimiq/.env` set `VIDEO_ENGINE_V2=false`, save, rerun `flutter run` |

---

# Instant rollback

In `swimiq/.env`:

```env
VIDEO_ENGINE_V2=false
```

Save → stop the app → `flutter run` again.  
You do **not** need to undo Part A or stop using Supabase.
