# SwimIQ / StrokeIQ

Swim analytics platform for tracking athlete performance, personal bests, goals, and meet results.

## Apps

| App | Platform | Directory |
|-----|----------|-----------|
| **SwimIQ V2 (Web)** | Streamlit | `app.py` |
| **SwimIQ V1 (Mobile)** | Flutter (Android + iOS) | `swimiq_app/` |

Both apps connect to the same Supabase backend.

## Web app (Streamlit)

- `app.py` - Streamlit dashboard and swim entry form.
- `requirements.txt` - Python dependencies.
- `data/swim_data.csv` - Sample swim session dataset.

## Setup

1. Create a Python virtual environment:
   ```bash
   python -m venv .venv
   ```
2. Activate the virtual environment:
   - Windows: `./.venv/Scripts/activate`
   - macOS/Linux: `source .venv/bin/activate`
3. Install dependencies:
   ```bash
   python -m pip install -r requirements.txt
   ```

## Run

```bash
python -m streamlit run app.py
```

## Features

- Add swim sessions with swimmer name, stroke, distance, time, stroke count, and date.
- Calculates stroke rate and distance per stroke (DPS).
- Displays trend charts for DPS, stroke rate, pace, and distance.
- Tracks personal records by swimmer and stroke.
- Shows weekly improvement percentages and efficiency recommendations.

## Mobile app (Flutter)

See [`swimiq_app/README.md`](swimiq_app/README.md) for setup and run instructions.

```bash
cd swimiq_app
flutter pub get
flutter run
```
