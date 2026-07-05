# SwimIQ Flutter App

Cross-platform swim performance tracker for **Android** and **iOS**, built with Flutter. This app connects to the same Supabase backend as the Streamlit reference app in the repo root.

## Milestone 2 — Auth (current)

- Supabase initialization with secure credential loading
- Email/password sign-up and sign-in via Supabase Auth
- Auth-aware routing (splash → login/signup → home)
- Sign-out support
- Placeholder home screen (V1 screens in Milestones 3–4)

**Not yet implemented:** Training log CRUD, dashboard, goals, meets, charts, settings.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.27+)
- Xcode (for iOS) and/or Android Studio (for Android)
- A Supabase project with **Email** auth provider enabled

### Supabase setup

1. In Supabase Dashboard → **Authentication** → **Providers**, enable **Email**.
2. For development, you may disable "Confirm email" under Email settings so sign-up signs in immediately.
3. Use your project URL and **anon** (publishable) key — never commit real keys.

## Setup

```bash
cd swimiq
flutter pub get
cp .env.example .env   # add SUPABASE_URL and SUPABASE_ANON_KEY
flutter run
```

Or with dart-define:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Test

```bash
cd swimiq
flutter test
flutter analyze
```

## Project structure

```
swimiq/lib/
├── main.dart
├── app.dart
├── config/env.dart
├── core/constants/       # Colors, routes, strings
├── core/utils/           # Swim time + auth validators
├── providers/            # AuthProvider
├── router/               # go_router with auth redirects
├── services/             # Supabase + Auth services
├── screens/
│   ├── splash_screen.dart
│   ├── auth/             # Login, signup
│   └── home_placeholder_screen.dart
└── widgets/
```

## Database schema

**No schema changes in Milestone 2.** Supabase Auth uses the built-in `auth.users` table. Display names are stored in user metadata (`display_name`). Linking auth users to `swimmers` / `race_logs` rows will happen in Milestone 3.

| Table | Usage |
|-------|-------|
| `auth.users` | Supabase Auth (email/password) |
| `race_logs` | Training sessions (Milestone 3) |
| `goals` | Swimmer goals (Milestone 4) |
| `meet_results` | Meet results (Milestone 4) |
| `swimmers` | Athlete passport (Milestone 4) |

## Roadmap

| Milestone | Scope | Status |
|-----------|-------|--------|
| 1 — Foundation | Project setup, secrets, splash | Done |
| 2 — Auth | Supabase + email/password login | **Done** |
| 3 — Data layer | Models, repositories, training log | Next |
| 4 — V1 screens | Dashboard, goals, meets, charts, settings | Planned |

## Reference

The Streamlit app (`app.py` in repo root) remains unchanged and serves as the functional reference.
