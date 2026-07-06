# Windows setup (paths with spaces)

If your Windows username or project path contains a **space** (for example `C:\Users\Kara Williams\...`), Flutter may fail with:

```text
'C:\Users\Kara' is not recognized as an internal or external command
Building native assets failed
```

Red squiggles in VS Code usually mean **`flutter pub get` failed** — the Dart code is fine; packages did not install.

SwimIQ avoids heavy native desktop builds. **Gemini video coaching** still runs via Supabase. **Pose metrics** run in **Chrome (Flutter web)**.

---

## Easiest fix — use drive `S:`

1. In File Explorer, open your **StrokeIQ** folder (the one that contains the `swimiq` folder).
2. Double-click **`swimiq\scripts\setup-short-path.bat`**
3. Open a **new** PowerShell window.
4. Run:

```powershell
S:
cd swimiq
.\run-chrome.ps1
```

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
$env:Path = "F:\bin;" + $env:Path
cd S:\swimiq
flutter clean
flutter pub get
flutter run -d chrome
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

## Logos

Brand files live in `assets\branding\` (`swimiq_icon.png`, `swimiq_hero.png`, `swimiq_logo.png`).  
After replacing them: `flutter clean` then `flutter run -d chrome`.
