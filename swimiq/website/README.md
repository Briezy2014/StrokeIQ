# Marketing / legal static pages (NOT the live app homepage)

These files (`index.html`, `privacy.html`, …) are the **old brochure** site.

**Do not upload `website/` alone to GoDaddy `public_html` if you want coaches to use the real SwimIQ app.**

## What goes on https://swimiqapp.com

| Goal | Upload this |
|------|-------------|
| Real SwimIQ app (login, dashboard, passport) | Flutter build: `swimiq/build/web/` via `PUBLISH-SWIMIQAPP-COM.bat` |
| Legal-only copies | `privacy.html` / `terms.html` / `ai.html` (copied automatically by the publish script) |

See: `docs/GODADDY_WEBSITE_UPLOAD.md`

## Sync legal text from the app

```bash
cd swimiq
python3 website/sync_legal.py
```

Then re-run the Flutter GoDaddy publish so legal HTML is copied into `build/web`.
