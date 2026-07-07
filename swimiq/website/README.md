# swimiqapp.com website

Static site that shows **all Flutter app features and updates** for parents, coaches, and App Store reviewers.

**Live domain:** https://swimiqapp.com (upload these files to GoDaddy)

## Pages

| File | URL |
|------|-----|
| `index.html` | https://swimiqapp.com/ |
| `privacy.html` | https://swimiqapp.com/privacy |
| `terms.html` | https://swimiqapp.com/terms |
| `ai.html` | https://swimiqapp.com/ai |

## Upload to GoDaddy (replace your current homepage)

1. Log in to [GoDaddy](https://www.godaddy.com) → **My Products**
2. Find **swimiqapp.com** → **Manage** → **Hosting** (or **Website Builder** → switch to **HTML** / file upload if available)
3. Open **File Manager** (cPanel) or **FTP**
4. Go to the web root folder (`public_html` or `httpdocs`)
5. **Upload everything** from this `website/` folder:
   - `index.html` (replaces old homepage)
   - `privacy.html`, `terms.html`, `ai.html`
   - folder `css/site.css`
6. Visit https://swimiqapp.com — you should see Features, Updates, Plans, Beta

### If you use GoDaddy Website Builder (drag-and-drop)

Website Builder cannot run custom HTML easily. Options:
- **Switch to GoDaddy Web Hosting (cPanel)** for this domain (~$5–10/mo), **or**
- Paste sections from `index.html` into builder pages manually, **or**
- Use **GitHub Pages** + point GoDaddy DNS (ask for help if needed)

## After you change legal text in the app

Legal pages must match `swimiq/assets/legal/*.txt`:

```bash
cd swimiq
python3 website/sync_legal.py
```

Then re-upload `privacy.html`, `terms.html`, and `ai.html` to GoDaddy.

## Redirect other domains

In GoDaddy, forward **swimiqapp.net** (and any others) → **https://swimiqapp.com**

## Email

Set up forwarding in GoDaddy:
- `support@swimiqapp.com` → your inbox
- `privacy@swimiqapp.com` → your inbox
