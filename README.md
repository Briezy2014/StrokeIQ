# SwimIQ

Swim performance tracking platform.

## Apps

| App | Path | Platform | Status |
|-----|------|----------|--------|
| **Flutter (primary)** | `swimiq/` | Android, iOS | In development |
| **Streamlit (reference)** | `app.py` | Web | Reference only — unchanged |

## Quick start — Flutter app

```bash
cd swimiq
flutter pub get
cp .env.example .env   # add your Supabase credentials
flutter run
```

See [swimiq/README.md](swimiq/README.md) for full setup.

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
