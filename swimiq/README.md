# SwimIQ Flutter App

Cross-platform swim performance tracker for **Android** and **iOS**, connected to the same Supabase backend as the Streamlit reference app.

## Version 1 — Complete

| Feature | Status |
|---------|--------|
| Splash + email/password auth | Done |
| Dashboard with SwimIQ Score + chart | Done |
| Training log (list, edit, delete) | Done |
| Add swim session + PB detection | Done |
| Personal bests | Done |
| Goals with progress + edit/delete | Done |
| Meet results + edit/delete | Done |
| Athlete passport (swimmer profile) | Done |
| Settings (account, sign out) | Done |
| Auto-link auth user to swimmer profile | Done |

## Setup

```bash
cd swimiq
flutter pub get
cp .env.example .env   # add SUPABASE_URL and SUPABASE_ANON_KEY
flutter run
```

Enable **Email** auth in Supabase Dashboard → Authentication → Providers.

## Test

```bash
cd swimiq
flutter test
flutter analyze
```

## Database schema

No schema changes for V1. Auth uses `auth.users`. Swimmer data uses existing tables with `swimmer` / `swimmer_name` keys linked from the authenticated user's display name.

## Reference

The Streamlit app (`app.py` in repo root) remains unchanged.
