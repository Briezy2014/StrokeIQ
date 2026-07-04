# SwimIQ (Flutter)

Cross-platform SwimIQ mobile app for **Android and iOS**, built with Flutter.

> Built in the Water. Driven by Possibility.

The existing Streamlit web app in the repository root remains unchanged as a reference implementation.

## Version 1 — Milestone 1 (current)

- Flutter project scaffold (`swimiq/`)
- Supabase connection via compile-time environment file
- Email/password authentication (Google & Apple placeholders)
- Splash screen with SwimIQ branding
- Main navigation shell (Dashboard, Training, Meets, Goals, Profile, Settings)
- Ported domain utilities from Streamlit (swim times, personal bests, SwimIQ Score)

## Prerequisites

- Flutter stable SDK (3.44+)
- Android SDK for Android builds
- Xcode for iOS builds (macOS only)

## Setup

1. Copy the Supabase environment template:

   ```bash
   cp supabase.env.example.json supabase.env.json
   ```

2. Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `supabase.env.json`.

3. Install dependencies:

   ```bash
   flutter pub get
   ```

## Run

```bash
flutter run --dart-define-from-file=supabase.env.json
```

## Build

```bash
# Android
flutter build apk --dart-define-from-file=supabase.env.json

# iOS (requires macOS + Xcode)
flutter build ios --dart-define-from-file=supabase.env.json
```

## Test

```bash
flutter test --dart-define-from-file=supabase.env.json
```

## Project structure

```
lib/
  core/          # theme, constants, config
  data/          # Supabase services and repositories
  domain/        # business logic ported from Streamlit
  features/      # UI screens by feature
  router/        # go_router navigation
```

## Schema note

Milestone 1 uses Supabase **Auth only**. Data tables (`race_logs`, `goals`, `meet_results`, `swimmers`) still use the existing `swimmer` text field from the Streamlit app. Linking auth users to swimmer records will be addressed before data features ship, with schema changes proposed first if needed.
