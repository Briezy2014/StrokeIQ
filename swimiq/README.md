# SwimIQ Flutter App

Native iOS and Android client for **SwimIQ Version 2: Athlete Performance**, connected to the existing Supabase backend used by the Streamlit app.

> If your local folder is named `swimiq_mobile`, use the same code inside that project — the repo path is `swimiq/`.

## Features

- **Swimmer gate** — enter a name/code to start (no password auth, matching Streamlit)
- **Dashboard** — SwimIQ Score, session metrics, history, and time progress chart
- **Personal Bests** — best times by stroke, distance, and course
- **Add Swim Session** — log training swims with PB detection
- **Goals** — set and view target times
- **Meet Results** — record and view competition results
- **Video Lab** — upload swim videos to Supabase Storage, playback, AI analysis
- **Athlete Passport** — Streamlit-style status cards, athlete details, AI Coach hub, profile editing
- **2024–2028 USA Swimming motivational standards** — full bundled dataset (500 events)

## Supabase setup (required for Video Lab + Standards import)

1. Open Supabase Dashboard → **SQL Editor**
2. Run `supabase/migrations/001_video_standards.sql`
3. Go to **Storage** → create bucket `swim-videos` (public recommended for V1 playback)
4. Ensure policies allow insert/select for your publishable key

### Tables

| Table | Purpose |
|-------|---------|
| `race_logs` | Training sessions (`swimmer`) |
| `goals` | Target times (`swimmer_name`) |
| `meet_results` | Meet results (`swimmer_name`) |
| `swimmers` | Athlete Passport profile |
| `swim_videos` | Uploaded video metadata |
| `swim_video_analyses` | AI coaching analysis results |
| `usa_time_standards` | USA Swimming motivational times |

If the new tables are missing, the app still runs — standards fall back to bundled seed JSON, and video upload shows an error until migration completes.

## Setup

### Prerequisites

- Flutter SDK 3.32+
- Android Studio (Windows/Android) and/or Xcode (iOS)

### Install dependencies

```bash
cd swimiq
flutter pub get
```

### Supabase configuration

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_KEY=your-publishable-key
```

## Run

```bash
cd swimiq
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

### Tomorrow quick start (after `git pull`)

1. `cd swimiq && flutter clean && flutter pub get`
2. `flutter run -d chrome` (or your device)
3. Enter swimmer **Aspyn**
4. Check **Passport** tab: Athlete Status cards, Coming Soon hub, AI Coach recommendation
5. Tap **Video Lab** from hub or bottom nav; run AI analysis on a video with notes

Live Supabase tests (optional — require working credentials):

```bash
flutter test test/aspyn_data_live_test.dart test/video_lab_integration_test.dart
```

## AI Swim Analysis (V1)

V1 uses a notes-and-metadata engine (`AiSwimAnalysisService`) that turns upload notes, goals, PBs, and standards into coaching priorities. Claude vision / frame-by-frame analysis is planned for SwimDNA™.

## Build for release

```bash
flutter build apk
flutter build ios --no-codesign
```
