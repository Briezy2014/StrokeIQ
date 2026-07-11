# Pose Metrics (MediaPipe-compatible) + Gemini

SwimIQ Video Lab uses **Gemini** for coaching reports on all platforms.

| Layer | Where it runs | What it does |
|-------|---------------|--------------|
| **Gemini coaching** | Supabase Edge Function | Watches the video + athlete context → parent-friendly coaching report |
| **Pose metrics** | Android (coming back) | BlazePose / MediaPipe-compatible body landmarks |

**Windows + Chrome:** Use Gemini coaching now. On-device pose was temporarily removed from web/desktop builds so Flutter runs on PCs where the username has a space (see [WINDOWS_SETUP.md](WINDOWS_SETUP.md)).

## How it works

1. Upload a swim clip in **Video Lab**
2. Tap **Run AI analysis**
3. The app calls the **analyze-swim-video** Edge Function (Gemini)
4. The report is saved and shown in the app

See [GEMINI_SETUP.md](GEMINI_SETUP.md) for API key + deploy steps.

## Platform support

| Platform | Gemini report | On-device pose |
|----------|---------------|----------------|
| **Web (Chrome)** | Yes | Coming back on Android |
| **Android** | Yes | Planned |
| **iOS** | Yes | Planned (Mac build required) |

## Tips for better Gemini reports

- Side-on or 45° camera angle works best
- Keep the full body in frame when possible
- Clips up to ~100 MB are supported (larger files use Gemini File API automatically)
- Add upload notes (start, underwater, strokes, breathing, finish)
- Pool lighting and clear water help landmark detection

## Technical note

The Flutter `pose_detection` package uses Google's **BlazePose** model — the same 33-landmark body topology as MediaPipe Pose. On **Chrome (Flutter web)**, frames are sampled from the HTML video element. Metrics are estimates, not official meet timing.

> **Windows note:** Use `run-chrome.bat` if your user folder contains spaces — see [WINDOWS_SETUP.md](WINDOWS_SETUP.md).

## Deploy checklist

1. [GEMINI_SETUP.md](GEMINI_SETUP.md) — API key + Edge Function
2. [WINDOWS_SETUP.md](WINDOWS_SETUP.md) — if `flutter run -d chrome` fails on Windows
3. `flutter pub get`
4. `flutter run -d chrome`
