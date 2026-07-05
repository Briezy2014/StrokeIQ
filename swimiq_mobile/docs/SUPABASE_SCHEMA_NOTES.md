# Supabase Schema Notes (Version 1)

These notes come from the existing Streamlit `app.py`. **No schema changes have been made.**

## Tables in use

| Table | Purpose |
|---|---|
| `race_logs` | Training sessions |
| `goals` | Swimmer goals |
| `meet_results` | Meet race results |
| `swimmers` | Athlete Passport profile |

## Column naming inconsistencies (must resolve before queries)

The Streamlit app uses **different swimmer column names** across tables:

| Table | Column used when **saving** | Column used when **loading** |
|---|---|---|
| `race_logs` | `swimmer` | `swimmer` |
| `goals` | `swimmer_name` | `swimmer` (via shared `load_table`) |
| `meet_results` | `swimmer_name` | `swimmer` (via shared `load_table`) |
| `swimmers` | `swimmer_name` | `swimmer_name` |

**Impact:** Goals and meet results may not load correctly in Streamlit unless the database has a `swimmer` column populated, or the filter column differs from what inserts use.

**Flutter plan:** Before implementing goals/meet services, verify the real column names in the Supabase Table Editor. Use whatever columns actually exist — do not change the schema without your approval.

## Other field notes

### `race_logs`
- `swimmer`, `stroke`, `distance`, `course`, `time_seconds`, `date`, `notes`, `event`

### `goals`
- `swimmer_name`, `event`, `current_time`, `goal_time`, `course`, `target_date`

### `meet_results`
- Insert uses `swim_time`
- Streamlit display references `time_s` (likely a bug in the web app)

### `swimmers`
- `swimmer_name`, `first_name`, `last_name`, `preferred_name`, `birthday`, `graduation_year`, `team`, `coach_name`, `primary_stroke`, `secondary_stroke`, `favorite_event`, `usa_swimming_id`, `school`, `athlete_notes`

## Auth linkage (Version 1 — implemented)

- Each Supabase Auth user maps to **one** swimmer profile.
- Link is stored in **Auth user metadata**: `swimmer_name` (no schema change).
- On sign-up, the app also creates a row in `swimmers` if one does not exist.
- `race_logs` queries should filter by `swimmer`.
- `goals` and `meet_results` inserts use `swimmer_name` — verify load column in Supabase before building those screens.
