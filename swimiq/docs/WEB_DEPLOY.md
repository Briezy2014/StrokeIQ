# Deploy SwimIQ Flutter web (GitHub Pages)

Share the **real Flutter app** in a browser. This replaces the old “README on GitHub Pages” site.

**Live URL (after setup below):**

**https://briezy2014.github.io/StrokeIQ/**

For **swimiqapp.com** (GoDaddy), also read **[WEB_SITE_STATUS.md](WEB_SITE_STATUS.md)** — fix SSL first.

---

## One-time setup (~5 minutes)

### 1. Add GitHub secrets

Repo → **Settings → Secrets and variables → Actions → New repository secret**

| Secret name | Value |
|-------------|--------|
| `SUPABASE_URL` | Your Supabase project URL (`https://….supabase.co`) |
| `SUPABASE_ANON_KEY` | Supabase **anon public** key (Dashboard → Project Settings → API) |

Same values as local `swimiq/.env`.

### 2. Switch GitHub Pages to Actions

Repo → **Settings → Pages**

- **Build and deployment → Source:** **GitHub Actions** (not “Deploy from a branch”)

Save. The legacy branch deploy that renders `README.md` will stop being the site.

### 3. Allow the web app in Supabase Auth

Supabase → **Authentication → URL Configuration**

| Field | Value |
|-------|--------|
| **Site URL** | `https://briezy2014.github.io/StrokeIQ/` (or `https://swimiqapp.com` if that is primary) |
| **Redirect URLs** (add) | `https://briezy2014.github.io/StrokeIQ/**` |
| | `https://swimiqapp.com/**` |
| | `http://localhost:**` |

### 4. Deploy

Push to `main`, or: **Actions → Deploy Flutter Web → Run workflow**

First run takes several minutes. Then open:

**https://briezy2014.github.io/StrokeIQ/**

You should see SwimIQ **Login / Sign up**, not the repo README.

---

## Local production build

```powershell
cd swimiq
.\scripts\build-web-release.ps1
```

Or for GoDaddy upload (reads `.env`, copies `.htaccess`):

```powershell
.\scripts\build-web-godaddy.ps1
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| “Supabase is not configured” | Set secrets `SUPABASE_URL` + `SUPABASE_ANON_KEY`, re-run workflow |
| Still see README / Jekyll | Pages source must be **GitHub Actions**, not branch `/` |
| Sign-up / email links fail | Add Pages URL under Supabase Redirect URLs |
| `https://swimiqapp.com` certificate error | Install trusted SSL in GoDaddy — see WEB_SITE_STATUS.md |

---

## Custom domain (optional)

Point `swimiqapp.com` at GitHub Pages (CNAME / A records per GitHub docs), add the domain under **Pages → Custom domain**, then update Supabase Site URL + Redirect URLs. You can keep GoDaddy DNS only and still host files on GitHub Pages.
