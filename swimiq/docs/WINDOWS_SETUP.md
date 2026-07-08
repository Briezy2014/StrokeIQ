# Windows setup (paths with spaces)

If your Windows username or project path contains a **space** (for example `C:\Users\Kara Williams\...`), Flutter may fail with:

```text
'C:\Users\Kara' is not recognized as an internal or external command
Building native assets failed
```

This happens because Dart **native hooks** (for example `objective_c`) receive paths that get split at the space in `Kara Williams`.

Red squiggles in VS Code usually mean **`flutter pub get` failed** — the Dart code is fine; packages did not install.

**Do not run `flutter pub get` directly from OneDrive paths with spaces.** Use the launchers below.

---

## Easiest fix (recommended)

1. In File Explorer, open your **StrokeIQ\swimiq** folder.
2. Double-click **`FIX-KARA-PATHS.bat`** once (creates `C:\SwimIQWork` junction — no spaces).
3. Double-click **`KARA-CLICK-THIS.bat`** to launch Chrome.

That is it. Wait 2–3 minutes for the first build.

### What the fix does

| Path | Purpose |
|------|---------|
| `C:\SwimIQWork` | Junction to your real StrokeIQ folder (no spaces in working path) |
| `C:\FlutterWork` | Junction to Flutter SDK if it lives under `Kara Williams` |
| `C:\SwimIQPub` | Pub cache (no spaces) — fixes `objective_c` hook errors |

---

## If you already ran `flutter pub get` and it failed

Close VS Code, then:

1. Double-click **`FIX-KARA-PATHS.bat`** (cleans `.dart_tool` and resets paths).
2. Double-click **`KARA-CLICK-THIS.bat`**.

Do **not** type `flutter pub get` in PowerShell from `C:\Users\Kara Williams\...` — always use the `.bat` launchers.

---

## Alternative — drive `S:` (older method)

1. In File Explorer, open your **StrokeIQ** folder (the one that contains the `swimiq` folder).
2. Double-click **`swimiq\scripts\setup-short-path.bat`**
3. Open a **new** PowerShell window.
4. Run:

```powershell
S:
cd swimiq
.\run-chrome.ps1
```

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

Move Flutter to `C:\flutter` and update PATH, **or** let `FIX-KARA-PATHS.bat` create `C:\FlutterWork` automatically.

---

## Web vs Streamlit vs phone

| What | How to tell |
|------|-------------|
| **Flutter web (correct)** | `KARA-CLICK-THIS.bat` or `flutter run -d chrome`. URL is `localhost` with a port **other than 8501**. Login screen. |
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
After replacing them: run **`FIX-KARA-PATHS.bat`**, then **`KARA-CLICK-THIS.bat`**.
