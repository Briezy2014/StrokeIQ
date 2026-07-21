# SwimIQ

Swim performance tracking platform.

## Apps

| App | Path | Platform | Status |
|-----|------|----------|--------|
| **Flutter (primary)** | `swimiq/` | Android, iOS | V1 complete — auth, training log, settings |
| **Streamlit (reference)** | `app.py` | Web | Reference only — unchanged |

> **Codespaces / devcontainer:** The default preview opens the **Streamlit** app on port 8501.
> To see Flutter changes, run `cd swimiq && flutter run` (or `flutter run -d chrome` for web).

## Quick start — Flutter app

```bash
cd swimiq
flutter pub get
cp .env.example .env   # add your Supabase credentials
flutter run
```

See [swimiq/README.md](swimiq/README.md) for full setup.

### Website (Flutter in the browser)

- Status / SSL fix: [swimiq/docs/WEB_SITE_STATUS.md](swimiq/docs/WEB_SITE_STATUS.md)
- GoDaddy upload: [swimiq/docs/WALKTHROUGH_SWIMIQAPP_COM.md](swimiq/docs/WALKTHROUGH_SWIMIQAPP_COM.md)
- GitHub Pages auto-deploy: [swimiq/docs/WEB_DEPLOY.md](swimiq/docs/WEB_DEPLOY.md)

### Android Play launch

- [swimiq/docs/ANDROID_LAUNCH_CHECKLIST.md](swimiq/docs/ANDROID_LAUNCH_CHECKLIST.md)
- [swimiq/docs/ANDROID_RELEASE.md](swimiq/docs/ANDROID_RELEASE.md)

## Quick start — Streamlit reference app

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .streamlit/secrets.toml.example .streamlit/secrets.toml   # add credentials
python -m streamlit run app.py
```

## Secrets

**Do not commit credentials.** The following files are gitignored:

- `.env`
- `.streamlit/secrets.toml`

Use the `.example` files as templates:

- `.env.example` — Flutter / shared
- `.streamlit/secrets.toml.example` — Streamlit

## License

© 2026 SwimIQ · Founded by Aspyn Briez
