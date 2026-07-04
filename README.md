# SwimIQ

**Built in the Water. Driven by Possibility.**  
Founded by Aspyn Briez

SwimIQ is a swim performance platform. **Version 1** is a native Android app with Supabase authentication and core athlete data management.

See the full product plan in [docs/ROADMAP.md](docs/ROADMAP.md) (Versions 1–8).

## Version 1 — Android App

### Features

- Supabase email/password authentication
- Dashboard with SwimIQ Score, sessions, personal bests, and goals
- Swimmer profile (Athlete Passport fields)
- Training log (add, list, delete sessions)
- Meet results (add, list, delete)
- Goals (add, list, delete)
- Time progress charts
- Settings (account, refresh, sign out)

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
3. Open the `android/` folder in Android Studio, or build from the command line:
   ```bash
   cd android
   ./gradlew assembleDebug
   ```
4. Install the debug APK on a device or emulator:
   ```bash
   adb install app/build/outputs/apk/debug/app-debug.apk
   ```

### Project structure

```
android/          # Kotlin + Jetpack Compose Android app
docs/ROADMAP.md   # Versions 1–8 development roadmap
supabase/         # Database migrations
app.py            # Legacy Streamlit prototype (Version 2 reference)
```

## Legacy Streamlit prototype

The original Streamlit dashboard is still available for reference:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
streamlit run app.py
```

---

© 2026 SwimIQ · Founded by Aspyn Briez
