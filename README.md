# SwimIQ

**Built in the Water. Driven by Possibility.**  
Founded by Aspyn Briez

SwimIQ is a swim performance platform. **Version 2 (Athlete Performance)** is the current Kotlin Android app with Supabase authentication and athlete analytics.

See the full product plan in [docs/ROADMAP.md](docs/ROADMAP.md) (Versions 1–8).

## Version 2 — Athlete Performance (Kotlin Android)

### Features

- Supabase email/password authentication
- Dashboard with SwimIQ Score™ breakdown, best/average times, and recent sessions
- **Personal Bests** screen grouped by stroke, distance, and course
- **Athlete Passport™** hero UI with status cards (score, focus, readiness, activity)
- Training log with **PB detection** and celebration on new best times
- Meet results, goals, time progress charts, and settings
- **Offline read cache** for dashboard and passport when network is unavailable

A Flutter reference app also lives in [`swimiq/`](swimiq/) (Streamlit-style swimmer gate, Video Lab).

### Prerequisites

- Android Studio Ladybug or newer (or Android SDK 35 + JDK 17)
- A Supabase project with the V1 schema applied

### Supabase setup

1. Create a Supabase project at [supabase.com](https://supabase.com).
2. Run the SQL in [supabase/migrations/001_swimiq_v1.sql](supabase/migrations/001_swimiq_v1.sql) in the Supabase SQL Editor.
3. Enable Email auth in **Authentication → Providers**.

### Android setup

1. Copy the example config:
   ```bash
   cp android/local.properties.example android/local.properties
   ```
2. Edit `android/local.properties`:
   ```properties
   sdk.dir=/path/to/Android/sdk
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your-anon-or-publishable-key
   ```
3. Build and test:
   ```bash
   cd android
   ./gradlew test assembleDebug
   ```
4. Install the debug APK:
   ```bash
   adb install app/build/outputs/apk/debug/app-debug.apk
   ```

### Project structure

```
android/          # Kotlin + Jetpack Compose Android app (V2)
swimiq/           # Flutter mobile app (reference / extended features)
docs/ROADMAP.md   # Versions 1–8 development roadmap
supabase/         # Database migrations
app.py            # Legacy Streamlit prototype
```

## Legacy Streamlit prototype

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
streamlit run app.py
```

---

© 2026 SwimIQ · Founded by Aspyn Briez
