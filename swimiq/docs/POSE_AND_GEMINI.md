# Pose Metrics (MediaPipe-compatible) + Gemini

SwimIQ Video Lab uses **Gemini** for coaching reports on all platforms.

| Layer | Where it runs | What it does |
|-------|---------------|--------------|
| **Gemini coaching** | Supabase Edge Function | Watches the video + athlete context → parent-friendly coaching report |
| **Pose metrics** | Web (Chrome) + Android planned | MediaPipe Pose Landmarker in browser |

**Windows + Chrome:** Gemini coaching + MediaPipe body-line metrics run in Chrome. 
On-device pose does not use Android Studio — only the browser.

| Platform | Gemini report | On-device pose |
|----------|---------------|----------------|
| **Web (Chrome)** | Yes | Yes (MediaPipe JS) |
| **Android** | Yes | Planned (native) |
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
