# SwimIQ Mobile (Flutter)

SwimIQ Version 1 is a cross-platform mobile app for Android and iOS that connects to the existing Supabase backend used by the Streamlit web app.

## Features

- Swimmer login by name/code (same as web app)
- Dashboard with SwimIQ Score, metrics, and time progress chart
- Personal bests by stroke, distance, and course
- Add swim sessions with PB detection
- Goals tracking
- Meet results
- Athlete Passport profile view and editing

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable channel)
2. Install platform tooling for your target:
   - Android: Android Studio + SDK
   - iOS: Xcode (macOS only)
3. From this directory:

```bash
cd swimiq_app
flutter pub get
flutter run
```

Supabase credentials are configured in `lib/config/supabase_config.dart` and match the existing backend.

## Project structure

```
lib/
  config/       Theme and Supabase settings
  models/       Data models for Supabase tables
  services/     Supabase API layer
  providers/    Riverpod state management
  screens/      App screens (6 tabs + login)
  utils/        Swim time parsing, PB logic, SwimIQ score
  widgets/      Reusable UI components
```

## Schema notes

The Flutter app uses the correct Supabase column names:

| Table | Swimmer filter | Time column |
|-------|----------------|-------------|
| `race_logs` | `swimmer` | `time_seconds` |
| `goals` | `swimmer_name` | `goal_time` |
| `meet_results` | `swimmer_name` | `swim_time` |
| `swimmers` | `swimmer_name` | — |

This fixes bugs in the Streamlit app where goals and meet results were filtered/displayed with mismatched column names.

## Tests

```bash
flutter test
flutter analyze
```
