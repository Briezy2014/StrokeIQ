# Windows setup (paths with spaces)

If your Windows username or project path contains a **space** (for example `C:\Users\Kara Williams\...`), Flutter may fail with:

```text
'C:\Users\Kara' is not recognized as an internal or external command
Building native assets failed
```

This happens because Dart **native hooks** (for example `objective_c`) receive paths that get split at the space in `Kara Williams`.

Red squiggles in VS Code usually mean **`flutter pub get` failed** — the Dart code is fine; packages did not install.

**Do not run `flutter pub get` directly from OneDrive paths with spaces.** Use the launchers below.

**First:** get the launcher files (they are on `main`):

```powershell
cd "C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ"
git pull origin main
```

You should see **`START-HERE.bat`**, **`FIX-KARA-PATHS.bat`**, and **`KARA-CLICK-THIS.bat`** in the **StrokeIQ** folder (and again inside **`swimiq`**).

---

## Easiest fix (recommended)

**Run one step at a time.** Do not double-click both `.bat` files at once.

Pick **one folder** — either **StrokeIQ** (parent) or **StrokeIQ\swimiq**. The same three files exist in both places; use whichever folder you have open in File Explorer.

| Step | File | How often |
|------|------|-----------|
| 1 | **`FIX-KARA-PATHS.bat`** | **Once** (first time, or if Flutter path errors come back) |
| 2 | **`LAUNCH-CHROME.bat`** or **`SWIMIQ-CHROME-NOW.bat`** or **`KARA-CLICK-THIS.bat`** | **Every time** you want to open SwimIQ in Chrome |

**Or** double-click **`START-HERE.bat`** — it runs Step 1, waits, then Step 2 for you.

1. In File Explorer, open your **StrokeIQ** folder.
2. Double-click **`START-HERE.bat`** (easiest), **or** run Step 1 then Step 2 yourself.

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

## `supabase is not recognized` in PowerShell

That means the **Supabase CLI is not installed** — it is **not required** to run SwimIQ in Chrome.

| What you want | What to run |
|---------------|-------------|
| **Open the app** | `KARA-CLICK-THIS.bat` |
| **Deploy AI video / Stripe** | Install CLI first — see **[SUPABASE_CLI_WINDOWS.md](SUPABASE_CLI_WINDOWS.md)** or double-click **`INSTALL-SUPABASE-CLI.bat`** |

Do **not** confuse `supabase login` with launching the Flutter app. They are separate steps.

---

## Logos

Brand files live in `assets\branding\` (`swimiq_icon.png`, `swimiq_hero.png`, `swimiq_logo.png`).  
After replacing them: run **`FIX-KARA-PATHS.bat`**, then **`KARA-CLICK-THIS.bat`**.
