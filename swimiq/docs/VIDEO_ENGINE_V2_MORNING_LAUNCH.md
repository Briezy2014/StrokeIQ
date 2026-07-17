# Elite Video Lab — Start From Zero (Do Every Step)

You have not done anything yet. Follow this top to bottom.

**Important — logins were NOT changed.**  
SwimIQ master login is still:

- **Email:** `briezy682014@gmail.com`  
- (your existing password — unchanged)

An earlier draft of these instructions wrongly used a different email as an *example allowlist*. That never changed Supabase Auth. Use the accounts below.

---

## Accounts and codes (use these)

| Who | How to sign in / unlock |
|-----|-------------------------|
| **Master** | `briezy682014@gmail.com` + your real password |
| **Demo / coach demo** | `demo@swimiqapp.com` / password `SwimIQ` |
| **Coach preview code** | In Settings → Plans & billing, redeem **`COACH-EVAL-14`** (also accepts legacy **`COACH-TRIAL-30`**) |
| **3-day Elite trial** | Starts automatically for new eligible accounts |

When `VIDEO_ENGINE_V2=true`:

- Master + demo always see **Elite Video Lab**
- Active Elite trial + coach Elite sneak peek also see **Elite Video Lab**
- Video analysis still follows normal Elite / trial / coach limits

---

# PART 0 — Get the code

1. Open Terminal (Mac) or PowerShell (Windows).
2. If you do not have the repo yet:

```bash
cd ~
git clone https://github.com/Briezy2014/StrokeIQ.git
cd StrokeIQ
```

If you already have it:

```bash
cd ~/StrokeIQ
```

(Use your real folder path if different.)

3. Switch to the Elite Video Lab branch:

```bash
git fetch origin
git checkout cursor/elote-m9-flutter-supabase-b7ef
git pull origin cursor/elote-m9-flutter-supabase-b7ef
```

---

# PART A — Update Supabase (browser)

**Why:** Creates Elite tables and makes videos private.

1. Go to https://supabase.com/dashboard → open your SwimIQ project  
2. Left side → **SQL Editor** → **New query**  
3. Open this file on your computer, copy all, paste into Supabase, click **Run**:  
   `swimiq/supabase/migrations/005_video_analysis_engine_v2.sql`  
4. **New query** → paste/run:  
   `swimiq/supabase/migrations/006_swim_videos_private_storage.sql`  
5. **New query** → paste/run:  
   `swimiq/supabase/migrations/007_drop_legacy_open_video_policies.sql`  
6. **New query** → paste/run this check:

```sql
SELECT policyname
FROM pg_policies
WHERE tablename IN ('swim_videos', 'swim_video_analyses')
ORDER BY tablename, policyname;
```

You should **not** see `swim_videos_all` or `swim_video_analyses_all`.

---

# PART B — Start the analysis server

**Why:** This is the program that analyzes videos. Keep this window open.

### B1. Copy keys
In Supabase → **Project Settings** (gear) → **API**, copy:
- Project URL  
- `anon` `public` key  
- `service_role` key  

### B2. Gemini key
Go to https://aistudio.google.com/apikey → **Create API key** → copy it.

### B3. Create backend settings file

```bash
cd ~/StrokeIQ/services/video_analysis
cp .env.example .env
```

Windows PowerShell: `copy .env.example .env`

Open `services/video_analysis/.env` and set:

```env
POSE_ENABLED=true
GEMINI_REPORT_ENABLED=true
GEMINI_API_KEY=paste_gemini_here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=paste_anon_here
SUPABASE_SERVICE_ROLE_KEY=paste_service_role_here
SUPABASE_AUTH_REQUIRED=true
SUPABASE_PERSIST_RESULTS=true
VIDEO_ENGINE_V2_ALLOWLIST=
CORS_ALLOW_ORIGINS=*
```

Leave `VIDEO_ENGINE_V2_ALLOWLIST` **blank** so coach-code users (any email) can call the API.  
Master + demo are always allowed even if you add a list later.

Save.

### B4. First-time Python setup

```bash
cd ~/StrokeIQ/services/video_analysis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python scripts/download_rtmdet.py
python scripts/download_rtmpose.py
```

Windows: `python -m venv .venv` then `.\.venv\Scripts\Activate.ps1`

### B5. Start server (leave this running)

```bash
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

### B6. Check it works
Second window:

```bash
curl -s http://localhost:8080/health
```

Or open http://localhost:8080/health in a browser.

---

# PART C — Turn Elite Video Lab on in the SwimIQ app

### C1. Create the app settings file

```bash
cd ~/StrokeIQ/swimiq
cp .env.example .env
```

Windows: `copy .env.example .env`

Open **`swimiq/.env`**.

### C2. Put these values in `swimiq/.env`

Use the **same** Supabase URL + anon key from Part B.  
Do **not** put service_role or Gemini here.

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=paste_anon_here

ANALYSIS_API_BASE_URL=http://localhost:8080
VIDEO_ENGINE_V2=true
VIDEO_ENGINE_V2_ALLOWLIST=
VIDEO_ENGINE_V2_DUAL_RUN=false
```

| Line | Meaning |
|------|---------|
| `ANALYSIS_API_BASE_URL` | Address of the Part B server |
| `VIDEO_ENGINE_V2=true` | Turn Elite Video Lab on |
| `VIDEO_ENGINE_V2_ALLOWLIST=` | Leave blank for first launch (master, demo, trial, and coach codes all work) |

If you test on a **real phone**, use your computer’s Wi‑Fi IP instead of localhost:

```env
ANALYSIS_API_BASE_URL=http://192.168.x.x:8080
```

Save the file.

### C3. Install packages and run the app

```bash
cd ~/StrokeIQ/swimiq
flutter pub get
flutter run -d chrome
```

Windows path-with-spaces helper (if you already use it):

```powershell
S:
cd swimiq
.\run-chrome.ps1
```

### C4. Sign in and open the Video tab

**Option 1 — Master**

1. Sign in as `briezy682014@gmail.com`  
2. Tap bottom tab **Video**  
3. Title should say **Elite Video Lab**  
4. Upload MP4 → **Run Elite Analysis**

**Option 2 — Demo**

1. Sign in as `demo@swimiqapp.com` / `SwimIQ`  
2. Tap **Video** → should say **Elite Video Lab**  
3. Run analysis the same way  

**Option 3 — Coach code on any account**

1. Sign in with that account  
2. Open **Settings** → **Plans & billing**  
3. Enter coach code **`COACH-EVAL-14`** (or legacy **`COACH-TRIAL-30`**) → redeem  
4. Tap **Video** → **Elite Video Lab** during the Elite AI sneak peek (up to 5 AI analyses)  

### C5. Success checklist

- [ ] Part B health URL works  
- [ ] Master login still `briezy682014@gmail.com`  
- [ ] Demo login still works  
- [ ] Coach code still redeems  
- [ ] Video tab title = **Elite Video Lab** when V2 is on  
- [ ] Upload + **Run Elite Analysis** works  

---

# Instant rollback

In `swimiq/.env`:

```env
VIDEO_ENGINE_V2=false
```

Save → stop app → `flutter run` again. Logins and coach codes are unchanged.
