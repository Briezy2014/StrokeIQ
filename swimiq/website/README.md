# swimiqapp.com website files

**Important:** The live site should run the **Flutter web app** (`flutter build web` → `build/web`), not only this brochure folder.

See:

- `docs/WEB_SITE_STATUS.md` — SSL + current site diagnosis  
- `docs/WALKTHROUGH_SWIMIQAPP_COM.md` — Flutter upload  
- `docs/WEB_DEPLOY.md` — GitHub Pages  

## Optional / legal pages in this folder

| File | URL |
|------|-----|
| `privacy.html` | https://swimiqapp.com/privacy |
| `terms.html` | https://swimiqapp.com/terms |
| `ai.html` | https://swimiqapp.com/ai |
| `delete-account.html` | https://swimiqapp.com/delete-account |
| `index.html` | Brochure only — do **not** overwrite Flutter `index.html` unless you want a marketing homepage instead of the app |

Upload legal HTML + `css/` into GoDaddy `public_html` **alongside** the Flutter build.

## After legal text changes

```bash
cd swimiq
python3 website/sync_legal.py
```

Re-upload `privacy.html`, `terms.html`, `ai.html`.
