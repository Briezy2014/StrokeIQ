# Windows setup (paths with spaces)

If your Windows username or project path contains a **space** (for example `C:\Users\Kara Williams\...`), Flutter may fail with:

```text
'C:\Users\Kara' is not recognized as an internal or external command
Building native assets failed
```

Red squiggles in VS Code usually mean **`flutter pub get` failed** — the Dart code is fine; packages did not install.

SwimIQ avoids heavy native desktop builds. **Gemini video coaching** still runs via Supabase. **Pose metrics** run in **Chrome (Flutter web)**.

---

## Easiest fix — use drive `S:` and the launcher script

**Do not run `flutter run -d chrome` directly** if your username is `Kara Williams`.  
The Pub cache path (`C:\Users\Kara Williams\AppData\...`) breaks native hooks.

1. In File Explorer, open your **StrokeIQ** folder (the one that contains the `swimiq` folder).
2. Double-click **`swimiq\scripts\setup-short-path.bat`** (once per PC reboot).
3. Open a **new** PowerShell window.
4. Run:

```powershell
S:
cd swimiq
.\run-chrome.ps1
```

Or double-click **`run-chrome.bat`**.

The launcher maps Flutter to `F:\` if needed, project to `S:\swimiq`, and sets **`PUB_CACHE=S:\pub-cache`** (no spaces).

5. Chrome should open with the **Login** screen and SwimIQ logo.

---

## If you are stuck in a git merge

```powershell
cd "C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ"
git merge --abort
git fetch origin main
git reset --hard origin/main
```

Then run `setup-short-path.bat` and `run-chrome.ps1` as above.

---

## Alternative — move the project

Copy the whole `StrokeIQ` folder to a path **without spaces**, for example `C:\StrokeIQ`:

```powershell
cd C:\StrokeIQ\swimiq
flutter clean
flutter pub get
flutter run -d chrome
```

---

## If Flutter SDK is also under a path with spaces

Move Flutter to `C:\flutter` and update PATH, **or** map a drive letter (PowerShell as Administrator):

```powershell
subst F: "C:\Users\Kara Williams\flutter"
subst S: "C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ"
```

Then:

```powershell
$env:PUB_CACHE = "S:\pub-cache"
New-Item -ItemType Directory -Force -Path $env:PUB_CACHE | Out-Null
$env:Path = "F:\bin;" + $env:Path
cd S:\swimiq
flutter clean
flutter pub get
.\run-chrome.ps1
```

---

## Web vs Streamlit vs phone

| What | How to tell |
|------|-------------|
| **Flutter web (correct)** | `run-chrome.bat` or `flutter run -d chrome`. URL is `localhost` with a port **other than 8501**. Login screen. |
| **Streamlit (wrong)** | URL is `localhost:8501`. Asks for swimmer name only. |
| **Phone app** | Installed app icon, not a browser tab. |

---

## After Chrome opens

1. **Sign up** or **Sign in** (not swimmer name).
2. **Passport** → set Aspyn’s **birthday** and **gender** → **Save**.
3. **Video Lab** → **Run AI Swim Analysis** again for Gemini feedback.

---

## Supabase keys required (fixes “assets/.env 404” in Chrome)

Flutter **web** does not load `.env` as a file in the browser. The launcher passes keys via `--dart-define`.

1. In `S:\swimiq`, copy the example file:

```powershell
copy .env.example .env
notepad .env
```

2. In [Supabase](https://supabase.com/dashboard) → your project → **Project Settings** → **API**, paste:
   - **Project URL** → `SUPABASE_URL=`
   - **anon public** key → `SUPABASE_ANON_KEY=`

3. Save `.env`, then launch:

```powershell
.\run-chrome.bat
```

Do **not** use raw `flutter run -d chrome` — use `run-chrome.bat` so keys and path fixes apply.

---

## Logos

One file only — **512×512 square PNG**:

```
assets\branding\swimiq_icon.png
```

Drag your PNG onto **`COPY-LOGO.bat`** (also updates web tab icon in `web\favicon.png` and `web\icons\`).

After replacing: close Chrome completely, then run **`LAUNCH-CHROME.bat`** (not hot reload).
