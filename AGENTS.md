# SwimIQ

Swim performance tracking platform. See `README.md` for a product overview.

## Apps / services

| App | Path | Stack | Notes |
|-----|------|-------|-------|
| Flutter app (primary) | `swimiq/` | Flutter/Dart (Android, iOS, web) | The main product. Docs in `swimiq/README.md`. |
| Streamlit reference app | `app.py` | Python (Streamlit) | Web reference app, port 8501. Kept unchanged. |
| Video analysis service | `services/video_analysis/` | Python (FastAPI) | Optional pose-analysis microservice; not required to run the two apps above. |

## Cursor Cloud specific instructions

Dependency installation is handled by the startup update script (`pip install -r requirements.txt` and `flutter pub get` in `swimiq/`). The notes below are the non-obvious things to know when running/testing here.

### Toolchain
- Flutter SDK (stable) lives in `~/flutter`; `~/flutter/bin` is added to `PATH` via `~/.bashrc`. In non-interactive shells that don't source `.bashrc`, call `~/flutter/bin/flutter` directly. Web is enabled (`flutter config --enable-web`).
- Python deps are installed with `pip3 install --break-system-packages` (Ubuntu 24.04 is an externally-managed environment).

### Credentials / Supabase (important gotcha)
- Both apps talk to Supabase. No Supabase credentials are provided in this environment, so **full auth and any data read/write cannot be exercised end-to-end** without real `SUPABASE_URL` / `SUPABASE_ANON_KEY` (and a live Supabase project). The "Coach demo login" button also hits the real Supabase backend, so it does not work offline.
- Flutter: reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` from `swimiq/.env` (see `swimiq/.env.example`) or from `--dart-define`. With no/placeholder values the app shows a "not connected" screen, so pass placeholder defines to reach the interactive login/signup UI. Client-side form validation (`AuthValidators`) works fully offline.
- Streamlit: reads `st.secrets["SUPABASE_URL"]` / `SUPABASE_KEY` from `.streamlit/secrets.toml` (gitignored; copy from `.streamlit/secrets.toml.example`). This file MUST exist or the app crashes on startup — a placeholder is enough to boot the UI since data queries are wrapped in try/except.

### Run / test / build commands
- Flutter lint: `cd swimiq && flutter analyze` (3 pre-existing warnings, no errors).
- Flutter tests: `cd swimiq && flutter test` (no backend needed; exercises core logic — scoring, standards, video models, passport metrics).
- Flutter web (dev): `cd swimiq && flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>`. The `web-server` device compiles Dart on the first browser request, so the first page load takes ~30-60s (blank page until then).
- Streamlit (dev): `python3 -m streamlit run app.py --server.port 8501 --server.headless true` (requires `.streamlit/secrets.toml`).
