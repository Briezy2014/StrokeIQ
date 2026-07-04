# SwimIQ Flutter App

Native iOS and Android client for **SwimIQ Version 2: Athlete Performance**, connected to the existing Supabase backend used by the Streamlit app.

## Features

- **Swimmer gate** — enter a name/code to start (no password auth, matching Streamlit)
- **Dashboard** — SwimIQ Score, session metrics, history, and time progress chart
- **Personal Bests** — best times by stroke, distance, and course
- **Add Swim Session** — log training swims with PB detection
- **Goals** — set and view target times
- **Meet Results** — record and view competition results
- **Athlete Passport** — profile display and editing

## Project structure

```
lib/
  config/          # Supabase connection settings
  core/            # Theme, constants, analytics, swim time utils
  data/            # Models and Supabase repository
  providers/       # Riverpod state management
  screens/         # Feature screens
  widgets/         # Shared UI components
```

## Setup

### Prerequisites

- Flutter SDK 3.32+
- Xcode (iOS) and/or Android Studio (Android)

### Install dependencies

```bash
cd swimiq
flutter pub get
```

### Supabase configuration

Credentials default to the same publishable key used by the Streamlit app. Override at build time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_KEY=your-publishable-key
```

## Run

```bash
cd swimiq
flutter run
```

## Test

```bash
cd swimiq
flutter test
flutter analyze
```

## Database notes

The app uses the existing Supabase schema without modifications:

| Table | Swimmer filter column |
|-------|----------------------|
| `race_logs` | `swimmer` |
| `goals` | `swimmer_name` |
| `meet_results` | `swimmer_name` |
| `swimmers` | `swimmer_name` |

## Build for release

```bash
flutter build apk
flutter build ios --no-codesign
```
