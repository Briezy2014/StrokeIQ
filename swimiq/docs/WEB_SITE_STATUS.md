# Fix swimiqapp.com + deploy the real Flutter app (read this first)

**Research finding (Jul 2026):** The Flutter web app **is already uploaded** to GoDaddy `public_html`.  
What breaks the site for most people is **HTTPS**: the SSL certificate on `swimiqapp.com` is **self-signed**, so Chrome/Safari show a warning or refuse to load the app.

| Check | Result |
|-------|--------|
| `http://swimiqapp.com` | Serves Flutter (`flutter_bootstrap.js`, `main.dart.js` ~4.8 MB) |
| `https://swimiqapp.com` | TLS fails / browser warning — cert issuer is the site itself, not a trusted CA |
| `https://briezy2014.github.io/StrokeIQ/` | Currently shows the **README** (Jekyll), **not** the Flutter app |

---

## Do these 3 things (in order)

### 1) Fix SSL on GoDaddy (required for https://swimiqapp.com)

1. GoDaddy → **My Products** → hosting for **swimiqapp.com** → **cPanel**
2. Open **SSL/TLS Status** or **Let's Encrypt SSL** / **AutoSSL**
3. Install / renew a **free trusted certificate** for `swimiqapp.com` and `www.swimiqapp.com`
4. Turn **Force HTTPS Redirect** ON only **after** the trusted cert is Active
5. Test in an **incognito** window: `https://swimiqapp.com` should show SwimIQ login **without** a certificate warning

**Phone script for GoDaddy support:**

> “My site swimiqapp.com has a self-signed SSL certificate. Browsers reject HTTPS. Please install AutoSSL / Let’s Encrypt for the domain and enable HTTPS redirect.”

### 2) Turn on automatic Flutter web deploy (GitHub Pages)

This gives a reliable backup URL while GoDaddy SSL is fixed, and auto-updates the browser app when code merges to `main`.

Follow **[WEB_DEPLOY.md](WEB_DEPLOY.md)** (secrets + Pages source = GitHub Actions).

After setup, the live Flutter app will be:

**https://briezy2014.github.io/StrokeIQ/**

### 3) Keep GoDaddy in sync when you change the app

```powershell
S:
cd swimiq
git pull origin main
powershell -ExecutionPolicy Bypass -File scripts\build-web-godaddy.ps1
```

Upload **everything inside** `build\web\` to GoDaddy `public_html` (replace old files).  
See **[WALKTHROUGH_SWIMIQAPP_COM.md](WALKTHROUGH_SWIMIQAPP_COM.md)**.

**Do not** upload only the small `website/` brochure folder if you want people to **use** the app. That folder is optional marketing/legal pages.

---

## What to tell people

> Try SwimIQ in your browser: **https://swimiqapp.com**  
> (If the browser warns about the certificate, use **http://swimiqapp.com** until SSL is fixed, or the GitHub link once Pages is switched on.)

---

## Android launch (next few days)

See **[ANDROID_RELEASE.md](ANDROID_RELEASE.md)** and **[ANDROID_LAUNCH_CHECKLIST.md](ANDROID_LAUNCH_CHECKLIST.md)**.
