# SwimIQ Mobile (Flutter)

Flutter app for **SwimIQ Version 1** — Android and iOS from one codebase.

The existing Streamlit app in the repo root is unchanged. This folder is the new mobile app.

## Prerequisites

Install the latest **stable** Flutter SDK on your machine:

1. Visit [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
2. Download Flutter for your OS
3. Add Flutter to your PATH
4. Run:

```bash
flutter doctor
```

Fix anything `flutter doctor` flags (Android Studio / SDK, licenses, etc.) before continuing.

## Setup

1. Go into this folder:

```bash
cd swimiq_mobile
```

2. Copy the environment template and add your Supabase credentials:

```bash
cp .env.example .env
```

Edit `.env`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

Use the same values as your Streamlit app (`.streamlit/secrets.toml` in the repo root).

**Alternative without a `.env` file:**

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

3. Install packages:

```bash
flutter pub get
```

## Run on Android

Connect a device or start an emulator, then:

```bash
flutter run
```

## Project structure

```
lib/
├── main.dart                 # App entry + Supabase init
├── app.dart                  # Theme + router
├── core/
│   ├── constants.dart        # App + table names
│   ├── supabase_config.dart  # Loads credentials
│   ├── theme.dart            # SwimIQ colors
│   └── swim_time_utils.dart  # Time parsing (ported from Streamlit)
├── models/                   # Coming next
├── services/                 # Coming next
└── screens/                  # UI screens
```

## Version 1 scope

- One authenticated user → one swimmer profile
- Splash, login/sign-up, dashboard, training log, meet results, goals, profile, settings, basic charts
- No video analysis, Stripe, or advanced AI yet

## Current milestone (Step 4–5)

- Splash screen → login or dashboard
- Email/password sign-up and sign-in (Supabase Auth)
- Bottom navigation: Dashboard, Training, Meets, Goals, Profile
- Settings (sign out) from Profile tab
- Athlete Passport profile loaded from `swimmers` table

Feature screens (training, meets, goals, dashboard charts) are placeholders until the next milestone.

## Known Supabase schema notes

See `docs/SUPABASE_SCHEMA_NOTES.md` before building data queries.
