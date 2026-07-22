# How to pull and merge all SwimIQ fixes (Windows)

Do this on the PC that has Flutter (`S:\` short path if you use it).

---

## Fast path (recommended)

Merge the important open PRs into `main` on GitHub first (Aspyn/Kara click **Merge** on each), then on the PC:

```powershell
S:
cd swimiq
git checkout main
git pull origin main
flutter pub get
```

Then rebuild what you need:

| Goal | Command |
|------|---------|
| Try in Chrome | `.\run-chrome.ps1` |
| Update website | `powershell -ExecutionPolicy Bypass -File scripts\build-web-godaddy.ps1` then upload `build\web` |
| Android AAB | `.\BUILD-ANDROID-NOW.bat` (after keystore — see ANDROID_RELEASE.md) |

---

## PRs to merge (order)

Merge these on GitHub (oldest first if GitHub shows conflicts, otherwise any order):

1. **#79** — Website SSL docs + Android Play signing readiness  
   `cursor/web-android-launch-ready-5847`
2. **#83** — Upcoming meets + Swimio IMX/IMR manual entry  
   `cursor/upcoming-meets-imx-fix-5847`
3. **This video PR** — Elote Video Engine V2 cutover (metrics first, Gemini for plan only)  
   `cursor/video-analysis-elote-cutover-5847`

After each merge on GitHub:

```powershell
git checkout main
git pull origin main
```

---

## If a PR isn’t merged yet but you need the code now

```powershell
S:
cd ..
git fetch origin
git checkout cursor/video-analysis-elote-cutover-5847
git pull origin cursor/video-analysis-elote-cutover-5847
cd swimiq
flutter pub get
```

---

## Video analysis after this PR (important)

**Correct path (what we want forever):**

1. Deploy Elote service (`services/video_analysis`) — see `VIDEO_ENGINE_V2_MORNING_LAUNCH.md`
2. Run Supabase SQL migrations `005`, `006`, `007`
3. In `swimiq/.env` set:

```
VIDEO_ENGINE_V2=true
ANALYSIS_API_BASE_URL=https://YOUR-ELOTE-HOST
VIDEO_ENGINE_V2_DUAL_RUN=false
```

4. Redeploy Edge Function only as rollback (`VIDEO_ENGINE_V2_DUAL_RUN=true` temporarily)

**Architecture:**

- **Elote (RTMPose)** measures the swim (≤ **2 minutes**)
- **Gemini** only writes the coaching **plan of action** from those metrics  
  (it does **not** invent stroke counts from watching the raw phone file alone)

**Legacy Edge Function** was upgraded to Gemini File API (up to ~100 MB) so phone clips stop dying at 18 MB — but that path is **not** the long-term engine. Turn V2 on as soon as Elote is hosted.

---

## Stuck?

- Wi-Fi blocking GitHub: see docs about corporate Wi-Fi / use phone hotspot  
- Path with spaces: `docs/WINDOWS_SETUP.md`  
- Website HTTPS: Economy hosting needs **Standard SSL** (AutoSSL not included)
