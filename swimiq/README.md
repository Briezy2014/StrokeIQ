# SwimIQ Flutter App

Cross-platform swim performance tracker for **Android** and **iOS**, connected to the same Supabase backend as the Streamlit reference app.

## Current status

| Milestone | Scope | Status |
|-----------|-------|--------|
| 1 | Foundation, secrets protection | Done |
| 2 | Supabase + email/password auth | Done |
| 3 | Data layer + training log CRUD | Done |
| 4 | Remaining V1 polish (settings, charts review) | Planned |

## Features

- **Email/password auth** via Supabase Auth (replaces swimmer name gate)
- **Dashboard** — SwimIQ Score, metrics, session history, time progress chart
- **Training Log** — list, edit, and delete swim sessions
- **Add Swim Session** — log training swims with PB detection
- **Personal Bests**, **Goals**, **Meet Results**, **Athlete Passport**
- **Video Lab** and **USA Swimming Standards** (from merged main branch)

## Setup

```bash
cd swimiq
flutter pub get
cp .env.example .env   # add SUPABASE_URL and SUPABASE_ANON_KEY
flutter run
```

### Supabase

1. Enable **Email** provider in Authentication → Providers
2. For dev, optionally disable email confirmation for instant sign-in
3. **Never commit** real keys — use `.env` (gitignored) or `--dart-define`

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Database schema

No schema changes for Milestone 3. Auth uses built-in `auth.users`. Swimmer data keys use the authenticated user's display name (or email prefix) as `swimmer` / `swimmer_name` in existing tables.

| Table | Key column | Notes |
|-------|------------|-------|
| `race_logs` | `swimmer` | Training sessions |
| `goals` | `swimmer_name` | Matches Streamlit `app.py` inserts |
| `meet_results` | `swimmer_name` | Uses `swim_time` column |
| `swimmers` | `swimmer_name` | Athlete passport |

## Test

```bash
cd swimiq
flutter test
flutter analyze
```

## Reference

The Streamlit app (`app.py` in repo root) remains unchanged and serves as the functional reference.
