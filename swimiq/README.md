# SwimIQ Flutter App

Cross-platform swim performance tracker for **Android** and **iOS**, built with Flutter. This app connects to the same Supabase backend as the Streamlit reference app in the repo root.

## Milestone 1 — Foundation (current)

- Flutter project scaffold targeting Android + iOS
- Secrets protected via `.gitignore` (no keys committed)
- SwimIQ brand theme and placeholder splash screen
- Shared swim-time utilities matching the Streamlit app
- Environment config via `--dart-define` or local `.env`

**Not yet implemented:** Supabase connection, auth, or V1 screens (coming in Milestones 2–4).

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.27+)
- Xcode (for iOS) and/or Android Studio (for Android)
- A Supabase project (same one used by the Streamlit app)

## Setup

### 1. Install dependencies

```bash
cd swimiq
flutter pub get
```

### 2. Configure Supabase credentials

**Never commit real keys.** Choose one method:

#### Option A — dart-define (recommended for CI/release)

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

#### Option B — local .env file (development)

```bash
cp .env.example .env
# Edit .env with your Supabase URL and anon key
```

Then add `.env` to `pubspec.yaml` under `flutter: assets:` and run `flutter pub get`.

### 3. Streamlit reference app secrets

For the Python Streamlit app at the repo root:

```bash
cp .streamlit/secrets.toml.example .streamlit/secrets.toml
# Edit secrets.toml with your credentials (file is gitignored)
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

## Project structure

```
swimiq/
├── lib/
│   ├── main.dart              # Entry point, env loading
│   ├── app.dart               # Theme + router
│   ├── config/
│   │   └── env.dart           # Supabase credential loader
│   ├── core/
│   │   ├── constants/         # Colors, strings
│   │   └── utils/             # Swim time parsing
│   ├── models/                # (Milestone 3)
│   ├── services/              # (Milestone 2)
│   ├── screens/               # UI screens
│   └── widgets/               # Shared widgets
├── assets/images/             # Logo and images
├── android/                   # Android platform
├── ios/                       # iOS platform
└── test/                      # Unit tests
```

## Database schema

The Flutter app will use the **existing Supabase schema** from the Streamlit reference app. No schema changes are planned for V1 unless required for Supabase Auth (see Milestone 2 notes).

| Table | Key columns |
|-------|-------------|
| `race_logs` | swimmer, date, stroke, distance, course, time_seconds, notes |
| `goals` | swimmer_name, event, goal_time, course, target_date |
| `meet_results` | swimmer_name, meet_name, meet_date, event, swim_time, course |
| `swimmers` | swimmer_name, profile fields (passport) |

## Roadmap

| Milestone | Scope |
|-----------|-------|
| **1 — Foundation** | Project setup, secrets, splash (this milestone) |
| **2 — Auth** | Supabase connection, email/password login & signup |
| **3 — Data layer** | Models, repositories, CRUD for race_logs |
| **4 — V1 screens** | Dashboard, training log, profile, goals, meets, charts, settings |

## Reference

The Streamlit app (`app.py` in repo root) remains unchanged and serves as the functional reference for business logic and data shapes.
