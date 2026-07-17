# Elite Video Lab — Exact Launch Instructions

Product name in the app: **Elite Video Lab**.

Do **A**, then **B**, then **C**. Do not skip ahead.

Your allowlist email for first launch: `aspyn682014@yahoo.com`

---

## A) Update your Supabase database (copy/paste SQL)

This tells Supabase how to store Elite Video Lab analyses and makes video storage private.

### A1. Open the SQL editor

1. On your computer, open a browser.
2. Go to: https://supabase.com/dashboard
3. Sign in.
4. Click your SwimIQ / StrokeIQ project.
5. In the left sidebar, click **SQL Editor**.
6. Click **New query**.

### A2. Run migration 005

1. On your computer, open this file from the repo:

   `swimiq/supabase/migrations/005_video_analysis_engine_v2.sql`

   (In GitHub: open the repo → `swimiq` → `supabase` → `migrations` → that file → click **Raw** → select all → copy.)

2. Paste the entire file into the Supabase SQL Editor.
3. Click **Run** (bottom right).
4. Wait until it says success. If it says the tables already exist, that is OK.

### A3. Run migration 006

1. Click **New query** again.
2. Open / copy this file:

   `swimiq/supabase/migrations/006_swim_videos_private_storage.sql`

3. Paste it into the SQL Editor.
4. Click **Run**.
5. Wait for success.

### A4. Run migration 007

1. Click **New query** again.
2. Open / copy this file:

   `swimiq/supabase/migrations/007_drop_legacy_open_video_policies.sql`

3. Paste it into the SQL Editor.
4. Click **Run**.
5. Wait for success.

### A5. Check that it worked

1. Click **New query**.
2. Paste this exactly:

```sql
SELECT policyname
FROM pg_policies
WHERE tablename IN ('swim_videos', 'swim_video_analyses')
ORDER BY tablename, policyname;
```

3. Click **Run**.
4. In the results, make sure you do **not** see:
   - `swim_videos_all`
   - `swim_video_analyses_all`

If those two names are gone, Part A is done.

---

## B) Start the Elite analysis computer program (backend)

This is the Python service that actually measures the swim video. The phone app talks to it.

You need a Mac/PC with this repo downloaded, Terminal, and Python.

### B1. Get your Supabase keys (keep these private)

1. In Supabase Dashboard, open your project.
2. Click the gear icon **Project Settings** (bottom left).
3. Click **API**.
4. Copy these three values into a notes app temporarily:
   - **Project URL** (looks like `https://xxxxx.supabase.co`)
   - **anon public** key (long string)
   - **service_role** key (long string — never put this in the Flutter app)

### B2. Get a Gemini API key (for coaching words only)

1. Go to: https://aistudio.google.com/apikey
2. Sign in with Google.
3. Click **Create API key**.
4. Copy the key into your notes app.

### B3. Create the backend settings file

1. Open Terminal.
2. Go to the analysis folder:

```bash
cd /path/to/StrokeIQ/services/video_analysis
```

Replace `/path/to/StrokeIQ` with wherever you cloned the repo (for example `~/StrokeIQ` or `~/Documents/StrokeIQ`).

3. Copy the example env file:

```bash
cp .env.example .env
```

4. Open `.env` in any text editor (TextEdit, VS Code, Cursor, nano).

5. Find and set these lines (use your real values; keep the quotes off unless the example already has them):

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=paste_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=paste_service_role_key_here
SUPABASE_AUTH_REQUIRED=true
SUPABASE_PERSIST_RESULTS=true
POSE_ENABLED=true
GEMINI_REPORT_ENABLED=true
GEMINI_API_KEY=paste_gemini_key_here
VIDEO_ENGINE_V2_ALLOWLIST=aspyn682014@yahoo.com
CORS_ALLOW_ORIGINS=*
```

6. Save the file.

### B4. Turn the backend on (first time setup if needed)

In Terminal, still in `services/video_analysis`:

```bash
source .venv/bin/activate
```

If that fails with “No such file”, create the environment once:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

(If pose models were never downloaded on this machine, also run the download scripts from `services/video_analysis/README.md`. If you already ran them before, skip.)

### B5. Start the server

```bash
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

Leave this Terminal window open. Do not close it while you test the app.

### B6. Confirm it is running

Open a **second** Terminal window and run:

```bash
curl -s http://localhost:8080/health
```

You should see JSON that includes something like `"status":"ok"` or healthy/ready text. If the command fails, the server in B5 is not running — go back to B5.

**Phone on the same Wi‑Fi as your computer?**  
Find your computer’s local IP (Mac: System Settings → Network, or Terminal `ipconfig getifaddr en0`).  
You will use `http://YOUR_IP:8080` in Part C instead of `http://localhost:8080`.

---

## C) Turn Elite Video Lab on in the SwimIQ app

### C1. Edit the Flutter env file

1. Open this file in the repo:

   `swimiq/.env`

   If it does not exist:

```bash
cd /path/to/StrokeIQ/swimiq
cp .env.example .env
```

2. Set these lines (same Supabase URL/anon key as Part B; **do not** put service_role or Gemini here):

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=paste_anon_key_here
ANALYSIS_API_BASE_URL=http://localhost:8080
VIDEO_ENGINE_V2=true
VIDEO_ENGINE_V2_ALLOWLIST=aspyn682014@yahoo.com
VIDEO_ENGINE_V2_DUAL_RUN=false
```

If you are testing on a physical phone, change `ANALYSIS_API_BASE_URL` to `http://YOUR_COMPUTER_IP:8080`.

3. Save the file.

### C2. Run the app

```bash
cd /path/to/StrokeIQ/swimiq
flutter pub get
flutter run
```

### C3. What you should see

1. Sign in with `aspyn682014@yahoo.com`.
2. Tap the **Video** tab at the bottom.
3. The title should say **Elite Video Lab** (not just Video Lab).
4. Upload a short swim MP4.
5. Tap **Run Elite Analysis**.
6. Fill the setup sheet → start → wait on the progress screen → open results.

If the title still says **Video Lab**, either:
- you are signed in with a different email, or
- `VIDEO_ENGINE_V2` is still `false`, or
- you did not restart the app after editing `.env`.

---

## Instant rollback

In `swimiq/.env` set:

```env
VIDEO_ENGINE_V2=false
```

Save, stop the app, run `flutter run` again. The Video tab goes back to the old analysis path.

---

## Do not do these

- Do not put `SUPABASE_SERVICE_ROLE_KEY` or `GEMINI_API_KEY` in `swimiq/.env`
- Do not delete the old Supabase Edge Function `analyze-swim-video`
- Do not leave `VIDEO_ENGINE_V2_ALLOWLIST` blank on first launch (blank means every user gets Elite)
