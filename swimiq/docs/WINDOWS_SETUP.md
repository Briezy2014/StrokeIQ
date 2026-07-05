# Windows setup (paths with spaces)

If your Windows username or project path contains a **space** (for example `C:\Users\Kara Williams\...`), Flutter may fail with:

```
'C:\Users\Kara' is not recognized as an internal or external command
Building native assets for package:objective_c failed.
```

SwimIQ fixes this in two ways:

1. **Removed heavy native packages** (`opencv_dart`, on-device `pose_detection`) that triggered the error on Chrome builds.
2. **Optional drive-letter shortcut** below if you still see path errors.

Gemini video coaching still works via Supabase. On-device MediaPipe pose returns on Android in a later release.

---

## Quick fix — run from VS Code

### 1. Abort any stuck git merge

```powershell
cd "C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ\swimiq"
git merge --abort
git fetch origin main
git reset --hard origin/main
```

### 2. Create `.env` (required for login)

```powershell
copy .env.example .env
```

Edit `.env` and add your Supabase URL and anon key (from Supabase Dashboard → Settings → API).

### 3. Clean rebuild

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

### 4. If you still get `'C:\Users\Kara' is not recognized`

Your **Flutter SDK** is probably installed under `C:\Users\Kara Williams\flutter`. Move it OR map a drive letter:

**Option A — Move Flutter (best long-term)**

1. Move folder to `C:\flutter`
2. Update PATH to `C:\flutter\bin`
3. Close and reopen VS Code
4. Run `flutter doctor`

**Option B — Map drive letters (no move required)**

Run **PowerShell as Administrator**:

```powershell
subst F: "C:\Users\Kara Williams\flutter"
subst S: "C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ"
```

Then in VS Code terminal:

```powershell
$env:Path = "F:\bin;" + $env:Path
cd S:\swimiq
flutter clean
flutter pub get
flutter run -d chrome
```

Or use the helper script:

```powershell
powershell -ExecutionPolicy Bypass -File tool\run_chrome.ps1
```

---

## Verify you have the latest app

After login you should see **auth screens** (not the old “Enter swimmer name” gate).

In Athlete Passport:
- **Upload profile photo** button
- **AI Coach hub** with module strip
- **Motivational Standards** showing age group (needs birthday + gender)

Set in Passport for Aspyn:
- **Birthday** (for correct 13-14 bracket)
- **Gender:** Girls
- **Graduation Year:** 2028

---

## Logos

Place files in `assets\branding\`:
- `swimiq_icon.png` — square icon
- `swimiq_hero.png` — wide banner

The repo also ships defaults in `assets\branding\` and `assets\images\`.

After changing logos: `flutter clean` then `flutter run -d chrome`.
