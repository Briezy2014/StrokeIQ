# GoDaddy: brochure pages only (optional)

**Primary site = Flutter web app.**  
Parents should use the app via `build/web` on `public_html`. See:

- **[WEB_SITE_STATUS.md](WEB_SITE_STATUS.md)** — SSL + what’s wrong with https today  
- **[WALKTHROUGH_SWIMIQAPP_COM.md](WALKTHROUGH_SWIMIQAPP_COM.md)** — build + upload Flutter  
- **[WEB_DEPLOY.md](WEB_DEPLOY.md)** — GitHub Pages auto-deploy  

This guide is only for the small **marketing/legal** files in `swimiq/website/`.

| What | Where |
|------|--------|
| **Real SwimIQ app** (login, dashboard) | Flutter `build/web` → GoDaddy `public_html` |
| **Legal / optional brochure** | `swimiq/website/` → same `public_html` (alongside Flutter, not instead of it) |

---

## Legal files to keep on the domain

```
privacy.html
terms.html
ai.html
delete-account.html
css/site.css
```

Upload these into `public_html` **without deleting** Flutter’s `index.html` / `main.dart.js` unless you intend to replace the homepage with the brochure.  
For App Store / Play Console, privacy + delete-account URLs must work even when the homepage is the Flutter app. Place legal HTML next to Flutter files; Flutter’s `.htaccess` SPA rewrite should exclude real files (Apache serves existing files before rewrite).

---

## SSL (do this first)

If https://swimiqapp.com shows a certificate warning, install **AutoSSL / Let’s Encrypt** in cPanel. Details: **WEB_SITE_STATUS.md**.

---

## Email

Forward `support@swimiqapp.com` and `privacy@swimiqapp.com` to your inbox in GoDaddy.
