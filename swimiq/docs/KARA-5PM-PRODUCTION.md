# Kara — 5 PM Production Checklist

**Branch:** `cursor/windows-chrome-spaces-fix-17e8`  
**One step at a time.** Double-click `.bat` files — do not paste paths into PowerShell.

---

## Before you start (2 min)

1. Double-click **`RESTORE-SCRIPTS.bat`**
2. Double-click **`FIX-KARA-PATHS.bat`** if Chrome failed before
3. Confirm **`swimiq\.env`** has `SUPABASE_URL` and `SUPABASE_ANON_KEY`

---

## Launch Chrome (web preview)

Double-click **`LAUNCH-CHROME.bat`** (or **`KARA-CLICK-THIS.bat`**)

---

## Tab-by-tab checklist

Sign in with your account (or Coach demo in debug Chrome — hidden on release builds).

| Tab | What to verify |
|-----|----------------|
| **Dashboard** | SwimIQ score, rope climb, Weekly Progress Report, training chart |
| **PBs** | Basic: in-app bests from log. Pro+: official meet PBs + USA cuts |
| **Log** | Opens on **Training** tab (not Meets). Sessions list works |
| **Add** | Save a training session — toast confirms |
| **Goals** | Add/view goals (Basic+) |
| **Meets** | Pro lock on Basic · add meet result on Pro |
| **Video** | Pro lock on Basic · upload on Pro · AI button says Elite |
| **Passport** | Pro lock on Basic · recruiting snapshot on Pro |

**Also check:** Settings → Membership → Compare plans table · AI Dryland Coach (Pro) · Race Intelligence (Elite)

---

## Build for GoDaddy (website)

Double-click **`SWIMIQ-BUILD-GODADDY-NOW.bat`**

Upload everything in `C:\SwimIQWork\swimiq\build\web\` to GoDaddy `public_html`.

---

## Build for Android (phone)

**First time only:** Install [Android Studio](https://developer.android.com/studio), open it once, accept SDK licenses.

Double-click **`SWIMIQ-BUILD-ANDROID-NOW.bat`**

APK output: `C:\SwimIQWork\swimiq\build\app\outputs\flutter-apk\app-release.apk`

Copy to your Android phone → open → install → sign in.

---

## Tier quick test

| Account | Expect |
|---------|--------|
| Basic (after trial) | Goals + Log work; Meets/Video/Passport locked |
| Pro | Meets, Video upload, Passport, Dryland Coach |
| Owner / Elite | AI video analysis + Race Intelligence |

---

## Logo

Icon only: copy `swimiq_icon.png` to `assets\branding\` if the app shows a placeholder.

---

## If something breaks

1. Close VS Code (unlocks `.dart_tool`)
2. **`RESTORE-SCRIPTS.bat`** → **`LAUNCH-CHROME.bat`**
3. Never type `S:\swimiq\...` in PowerShell — use File Explorer + `.bat` files only

**Tests in cloud:** 96/96 pass before this checklist was written.
