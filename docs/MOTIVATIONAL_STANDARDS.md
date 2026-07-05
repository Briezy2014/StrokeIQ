# USA Swimming Motivational Standards

Official reference dataset for SwimIQ (2024-2028 quad).

## Database

Apply the migration in Supabase SQL Editor:

`supabase/migrations/20240705000000_create_motivational_standards.sql`

Table: `motivational_standards`

| Column | Description |
|---|---|
| age_group | e.g. `11-12`, `13-14` |
| gender | `M` or `F` |
| course | `SCY`, `SCM`, `LCM` |
| event | e.g. `100 Freestyle` |
| b_time … aaaa_time | Cutoff times in seconds |
| version | e.g. `2024-2028 USA Swimming Motivational Standards` |

## Import from official PDF

When you have the USA Swimming PDF:

```bash
pip install pdfplumber supabase

python scripts/import_motivational_standards.py \
  --pdf path/to/2024-2028-motivational-standards.pdf \
  --output data/motivational_standards.json

python scripts/import_motivational_standards.py \
  --pdf path/to/standards.pdf \
  --supabase-url YOUR_URL \
  --supabase-key YOUR_SERVICE_ROLE_KEY
```

No placeholder data is shipped — the table starts empty until you import.

## Shared code

| Layer | Location |
|---|---|
| Flutter repository | `swimiq_mobile/lib/services/motivational_standards_repository.dart` |
| Flutter analytics | `swimiq_mobile/lib/services/standards_analytics.dart` |
| Python analytics | `standards_analytics.py` |
| Python Supabase access | `standards_service.py` |
| PDF importer | `scripts/import_motivational_standards.py` |
