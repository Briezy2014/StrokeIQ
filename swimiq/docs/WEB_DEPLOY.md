# Deploy SwimIQ on the Web (before mobile launch)

Share SwimIQ in a browser while App Store / Play Store builds are in progress.

**Live URL (after setup below):**

**https://briezy2014.github.io/StrokeIQ/**

---

## One-time setup (about 5 minutes)

### 1. Add GitHub secrets

In GitHub: **StrokeIQ repo → Settings → Secrets and variables → Actions → New repository secret**

| Secret name | Value |
|-------------|--------|
| `SUPABASE_URL` | `https://bryurwyeosbffvfpdpbv.supabase.co` (your project URL) |
| `SUPABASE_ANON_KEY` | Your Supabase **anon public** key (from Dashboard → Project Settings → API) |

These are the same values in your local `swimiq/.env`.

### 2. Turn on GitHub Pages

GitHub → **StrokeIQ → Settings → Pages**

- **Build and deployment → Source:** `GitHub Actions`

Save. No branch picker needed — the workflow deploys for you.

### 3. Allow the web app in Supabase Auth

Supabase Dashboard → **Authentication → URL Configuration**

| Field | Value |
|-------|--------|
| **Site URL** | `https://briezy2014.github.io/StrokeIQ/` |
| **Redirect URLs** (add) | `https://briezy2014.github.io/StrokeIQ/**` |
| | `http://localhost:**` (keep for local dev) |

Save.

### 4. Deploy

Push to `main` (or run the workflow manually):

GitHub → **Actions → Deploy Flutter Web → Run workflow**

First deploy takes ~5–8 minutes. When it finishes, open:

**https://briezy2014.github.io/StrokeIQ/**

You should see the SwimIQ **Login / Sign up** screen.

---

## Share the link

Use this when spreading the word:

> **Try SwimIQ in your browser:** https://briezy2014.github.io/StrokeIQ/  
> Built in the Water. Driven by Possibility.

---

## Local production build (optional)

```powershell
cd swimiq
.\scripts\build-web-release.ps1
```

Output is in `swimiq/build/web/` — upload anywhere that hosts static files.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| “Supabase is not configured” on the live site | Check GitHub secrets `SUPABASE_URL` and `SUPABASE_ANON_KEY`, then re-run the workflow |
| Sign-up / email links fail | Add the GitHub Pages URL under Supabase **Redirect URLs** (step 3) |
| Old Streamlit page (`localhost:8501`) | That is a different app — use the GitHub Pages link above |
| Workflow fails on Flutter SDK | Re-run workflow; `stable` Flutter is used automatically |

---

## Custom domain later (optional)

Buy a domain (e.g. `swimiq.app`), add it under GitHub **Pages → Custom domain**, and update Supabase **Site URL** + **Redirect URLs** to match.
