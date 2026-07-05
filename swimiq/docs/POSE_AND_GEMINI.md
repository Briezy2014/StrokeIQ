# Pose Metrics (MediaPipe-compatible) + Gemini

SwimIQ Video Lab uses **two layers** of AI:

| Layer | Where it runs | What it does |
|-------|---------------|--------------|
| **Pose metrics** | On your phone or browser | MediaPipe-compatible BlazePose (33 body points) — body line, hip drop, arm cycles, kick symmetry |
| **Gemini coaching** | Supabase server | Watches the video + reads pose numbers → parent-friendly coaching report |

iOS builds when you have a Mac. Android and Flutter Web are supported now.

## How it works

1. You upload a swim clip in **Video Lab**
2. The app samples frames and runs **on-device pose detection**
3. Pose numbers are sent with the video to **Gemini** (via Edge Function)
4. The combined report is saved and shown in the app

No extra signup beyond Gemini (see [GEMINI_SETUP.md](GEMINI_SETUP.md)).

## Platform support

| Platform | Pose metrics | Gemini report |
|----------|--------------|---------------|
| **Android** | Yes | Yes |
| **Web** | Yes | Yes |
| **iOS** | Yes (when built on Mac) | Yes |

## Tips for better pose metrics

- Side-on or 45° camera angle works best
- Keep the full body in frame when possible
- Clips under ~18 MB work best for Gemini
- Pool lighting and clear water help landmark detection

## Technical note

The Flutter `pose_detection` package uses Google's **BlazePose** model — the same 33-landmark body topology as MediaPipe Pose. Metrics are estimates, not official meet timing.

## Deploy checklist

1. [GEMINI_SETUP.md](GEMINI_SETUP.md) — API key + Edge Function
2. `flutter pub get`
3. `flutter run` on Android or `flutter run -d chrome` for web

No separate MediaPipe API key is required — pose runs on-device.
