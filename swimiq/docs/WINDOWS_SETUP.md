# Windows setup (Kara / paths with spaces)

Flutter’s native build tools **break** when your Windows user folder has a **space** in it, for example:

`C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ`

You may see:

```text
'C:\Users\Kara' is not recognized as an internal or external command
Building native assets failed
```

Red squiggles in VS Code usually mean **`flutter pub get` failed** — the code is fine; packages did not install.

## Fix (recommended): use drive `S:`

1. In File Explorer, open your **StrokeIQ** folder (the one that contains the `swimiq` folder).
2. Double-click **`swimiq\scripts\setup-short-path.bat`**  
   (or run it from a terminal in that folder).
3. Open a **new** PowerShell window.
4. Run:

```powershell
S:
cd swimiq
.\run-chrome.ps1
```

5. Chrome should open with the **Login** screen (SwimIQ logo).

## Alternative: move the project

Copy the whole `StrokeIQ` folder to a path **without spaces**, for example:

`C:\StrokeIQ`

Then:

```powershell
cd C:\StrokeIQ\swimiq
flutter pub get
flutter run -d chrome
```

## Web vs mobile vs Streamlit

| What | How to tell |
|------|-------------|
| **Flutter web (correct)** | You ran `run-chrome.bat` or `flutter run -d chrome`. URL is `localhost` with a port **other than 8501**. Login screen. |
| **Streamlit (wrong)** | URL is `localhost:8501`. Asks for swimmer name only. |
| **Phone app** | Installed app icon, not a browser tab. |

## After Chrome opens

1. **Sign up** or **Sign in** (not swimmer name).
2. **Passport** → set Aspyn’s **birthday** and **gender** → Save.
3. **Video Lab** → **Run AI Swim Analysis** again for Gemini feedback.

Pose metrics run in **Chrome web**. Gemini runs via Supabase when `GEMINI_API_KEY` is set on the Edge Function.
