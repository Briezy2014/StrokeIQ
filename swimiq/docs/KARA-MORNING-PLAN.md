# Kara — Morning Plan for SwimIQ (Chrome + GoDaddy)

**Read this once with coffee.** Do **one step at a time**. Do **not** type `flutter run` by hand.

Branch to use today: **`cursor/windows-chrome-spaces-fix-17e8`**

---

## What was audited overnight (Jul 2026)

| Check | Result |
|-------|--------|
| Flutter tests | **91 / 91 pass** |
| Web release build | **Builds successfully** |
| Windows Chrome launcher | **`SWIMIQ-CHROME-NOW.bat`** — subst/path fixes included |
| GoDaddy build launcher | **`SWIMIQ-BUILD-GODADDY-NOW.bat`** — copies `.htaccess`, validates output |
| Schedule photo upload | Code path OK (`uploadSchedulePhoto` → Supabase `swim-videos` bucket) |
| Recruiting snapshot | Auto-fills from passport + PBs |
| Video Lab | Pro/con cards, coach notes, no “cannot confirm AI” text |
| Logos | **Built-in gradient fallback** shows until you drop PNGs in `assets/branding/` |
| `.env` | Must live in **`swimiq\.env`** (not parent StrokeIQ folder) |

---

## Golden rules (avoid overnight errors)

1. **Never** run `flutter run -d chrome` from VS Code or a random terminal.
2. **Always** double-click **`SWIMIQ-CHROME-NOW.bat`** for local preview.
3. **Always** double-click **`SWIMIQ-BUILD-GODADDY-NOW.bat`** for GoDaddy build.
4. Your Windows username has a **space** (`Kara Williams`) — launchers map **S:** and **F:** drives for you.
5. After a launcher runs, you should see work happening on **`S:\swimiq`**.

---

## Phase 1 — Get the latest code (5 minutes)

Open **PowerShell** (one command, wait for it to finish):

```powershell
cd "C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ\swimiq"
git pull origin cursor/windows-chrome-spaces-fix-17e8
```

You should see files like:

- `SWIMIQ-CHROME-NOW.bat`
- `SWIMIQ-BUILD-GODADDY-NOW.bat`
- `docs/KARA-MORNING-PLAN.md` (this file)

If `scripts\` looks empty: double-click **`RESTORE-SCRIPTS.bat`**.

---

## Phase 2 — Diagnose (2 minutes)

Double-click **`DIAGNOSE.bat`** in the `swimiq` folder.

Look for **`[OK]`** on:

- `SWIMIQ-CHROME-NOW.bat` / `.ps1`
- `SWIMIQ-BUILD-GODADDY-NOW.bat` / `.ps1`
- `.env`

`[WARN]` on S: or F: is normal **before** you run the Chrome launcher.

---

## Phase 3 — Fix `.env` (3 minutes)

Open **`S:\swimiq\.env`** in Notepad (create from `.env.example` if missing).

Must have **exactly** these lines (real values, no typos):

```
SUPABASE_URL=https://bryurwyeosbffvfpdpbv.supabase.co
SUPABASE_ANON_KEY=eyJ...your anon key...
```

Common mistakes:

| Wrong | Right |
|-------|-------|
| `https:https//` | Single `https://` |
| `.env` in `StrokeIQ\` parent folder | `.env` in **`StrokeIQ\swimiq\`** |
| Placeholder `your-project` | Real Supabase URL |

Save and close Notepad.

---

## Phase 4 — Preview in Chrome (5–10 minutes first time)

1. Close any old Flutter/Chrome windows.
2. Double-click **`SWIMIQ-CHROME-NOW.bat`** (not `LAUNCH-CHROME.bat`, not VS Code F5).
3. Wait **1–2 minutes** — first run runs `pub get`.
4. Chrome should open SwimIQ login.

**If it fails**, copy the **last 10 lines** of the black window. Common fixes:

| Error | Fix |
|-------|-----|
| `'C:\Users\Kara' is not recognized` | You skipped the `.bat` — use **`SWIMIQ-CHROME-NOW.bat`** only |
| `directory name is invalid` (subst) | Pull latest branch; launcher now steps to `C:\` before mapping S: |
| `.env needs real SUPABASE_URL` | Fix Phase 3 |
| `assets/.env 404` | Same — launcher passes `--dart-define`; don’t use raw `flutter run` |

---

## Phase 5 — Visual checklist (click through the app)

Log in and confirm each area looks **gradient / polished** (not plain gray headers):

| Tab / screen | What to look for |
|--------------|------------------|
| **Dashboard** | Logo banner, SwimIQ score hero, **Daily Rope Climb** card, badges |
| **PBs** | Gradient hero + event cards |
| **Goals** | Hero + **pie chart** progress |
| **Log** | Hero + schedule section; attach a **schedule photo**, save, see URL in notes |
| **Video Lab** | Hero + pro/con cards, coach notes, next race goal |
| **Meet Results** | Hero + gradient event cards |
| **USA Standards** | Hero + motivational cuts |
| **Passport** | Recruiting snapshot card; edit honors / college interests |
| **Race Intelligence** (from Dashboard schedule) | Gradient hero + meet-day plan |

**Logos:** If you haven’t copied official PNGs yet, you’ll see the **built-in SWIMIQ gradient logo** — that’s OK for today.

**Optional — your real logos:** Copy to `S:\swimiq\assets\branding\`:

- `swimiq_hero.png`
- `swimiq_icon.png`

Then run **`SWIMIQ-CHROME-NOW.bat`** again.

---

## Phase 6 — Build for GoDaddy (5–10 minutes)

**Only after Chrome preview looks good.**

Double-click **`SWIMIQ-BUILD-GODADDY-NOW.bat`**.

Wait for:

```
BUILD DONE
Upload ALL files in:
  S:\swimiq\build\web\
```

Confirm folder contains `index.html`, `main.dart.js`, `assets/`, `.htaccess`.

---

## Phase 7 — Upload to GoDaddy (15–20 minutes)

1. Log into **GoDaddy** → **My Products** → **swimiqapp.com** → **Manage** → **File Manager** (or use FTP).
2. Open **`public_html`**.
3. **Do not delete `cgi-bin`.**
4. Select old Flutter files (`index.html`, `main.dart.js`, `flutter.js`, `assets/`, etc.) and delete or move to a backup folder.
5. Upload **everything** inside **`S:\swimiq\build\web\`** into `public_html`.
6. Open **`https://swimiqapp.com`** in **Incognito** (Ctrl+Shift+N).
7. Log in — same Supabase account as Chrome preview.

Full detail: `docs/WALKTHROUGH_SWIMIQAPP_COM.md`

---

## Phase 8 — Save / upload features to verify

| Feature | How to test |
|---------|-------------|
| Training log entry | Log tab → add session → refresh page → still there |
| Meet result | Meet Results → save → still there |
| Schedule + photo | Log → schedule form → attach JPG → Save → notes show `Schedule photo: https://...` |
| Passport edits | Passport → Save → recruiting snapshot updates |
| Video analysis | Video Lab → analyze (needs Supabase edge function + API keys deployed) |

Schedule photos use Supabase storage bucket **`swim-videos`**. If upload fails, check Supabase dashboard → Storage → policies for that bucket.

---

## Phase 9 — Stripe / Supabase (when Wi‑Fi is stable)

Not required to **see** the app today, but needed for paid checkout:

1. Follow **`docs/STRIPE_SETUP.md`** for Price IDs.
2. Run **`scripts\set-supabase-stripe-secrets.ps1`** once (PowerShell as admin if needed).
3. Deploy edge functions: `analyze-swim-video`, `create-stripe-checkout`, `stripe-webhook`.

---

## Quick reference — files that matter

| Purpose | File |
|---------|------|
| **Chrome preview** | `swimiq/SWIMIQ-CHROME-NOW.bat` |
| **GoDaddy build** | `swimiq/SWIMIQ-BUILD-GODADDY-NOW.bat` |
| **Health check** | `swimiq/DIAGNOSE.bat` |
| **Restore scripts** | `swimiq/RESTORE-SCRIPTS.bat` |
| **Secrets** | `swimiq/.env` |
| **Upload source** | `swimiq/build/web/` |
| **GoDaddy guide** | `swimiq/docs/WALKTHROUGH_SWIMIQAPP_COM.md` |

---

## If something still breaks

1. Run **`DIAGNOSE.bat`** — screenshot the output.
2. Run **`SWIMIQ-CHROME-NOW.bat`** — copy the **last error lines**.
3. Confirm folder is **`...\StrokeIQ\swimiq`** (not parent StrokeIQ, not “AspynBriez Website Assets”).

You’ve got this. One `.bat` at a time. ☕🏊‍♀️
