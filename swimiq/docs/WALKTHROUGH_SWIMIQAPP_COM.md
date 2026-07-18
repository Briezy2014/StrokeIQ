# Walkthrough: swimiqapp.com shows the REAL SwimIQ app (in the browser)

**Read this first — one sentence:**

People cannot install the iPhone/Android app yet, but they **can use SwimIQ in Chrome/Safari** if you put the **Flutter web build** on GoDaddy at **swimiqapp.com**.

**Do not upload `swimiq/website/` (marketing brochure) as the homepage.**  
That is why the live site was stuck on the old page. Use `PUBLISH-SWIMIQAPP-COM.bat` → upload `build/web` / the zip.

That is how they **see and try the functionality** before the app stores launch.

---

## What “route to the Flutter app” actually means

| What people think | What actually works **now** |
|-------------------|-------------------------------|
| Website opens the App Store app | ❌ Not until Android/iPhone are published |
| Website **is** the Flutter app in a browser | ✅ **Yes — do this** |
| Static page describing features | ✅ Easier but **cannot click around** the app |

**We use option 2:** build Flutter for web → upload to GoDaddy → **swimiqapp.com runs SwimIQ** (login, dashboard, passport, etc.).

---

# PART A — On your Windows PC (build the website-app)

### Step 1 — Open PowerShell

### Step 2 — Go to SwimIQ and get latest code

```powershell
S:
cd swimiq
git pull origin main
```

You must see a **`website`** folder AND be able to run Flutter (same as when you use Chrome).

### Step 3 — Make sure Supabase keys exist

Open `S:\swimiq\.env` in Notepad. It must have (with your real values):

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbG...
```

Same keys you use when SwimIQ works in Chrome on your PC.

### Step 4 — Build the web version of SwimIQ

```powershell
S:
cd swimiq
powershell -ExecutionPolicy Bypass -File scripts\build-web-godaddy.ps1
```

Wait 2–5 minutes. When it says **Done**, you have a folder:

```
S:\swimiq\build\web\
```

Inside are many files (`index.html`, `main.dart.js`, `assets`, etc.). **That entire folder is what GoDaddy needs.**

### Step 5 — Quick test on your PC (optional)

```powershell
cd S:\swimiq\build\web
python -m http.server 8080
```

Open **http://localhost:8080** — you should see SwimIQ login.  
(Stop with Ctrl+C when done.)

---

# PART B — GoDaddy (put it on swimiqapp.com)

### Step 6 — Log into GoDaddy

1. **godaddy.com** → Sign in  
2. **My Products** → **swimiqapp.com** → **Manage**

### Step 7 — Open File Manager

1. Click **Hosting** or **cPanel Admin**  
2. Click **File Manager**  
3. Open folder **`public_html`**

This folder is **swimiqapp.com**.

### Step 8 — Clear old site (important)

Inside `public_html`, delete or rename the **old** files (old `index.html`, etc.) so they do not conflict.

- Optional: rename old `index.html` to `index-OLD.html`

### Step 9 — Upload the Flutter web build

1. On your PC, open **`S:\swimiq\build\web`**  
2. Select **ALL files and folders** inside (not the `web` folder itself — everything **inside** it)  
3. In GoDaddy File Manager → **Upload**  
4. Upload everything to **`public_html`**

When finished, `public_html` should contain:
- `index.html`
- `flutter_bootstrap.js` (or similar)
- `main.dart.js`
- folders like `assets`, `canvaskit`, `icons`

Upload can take **10–20 minutes** (large files). Do not close the browser until done.

### Step 10 — Check swimiqapp.com

1. Wait 2 minutes  
2. Open **https://swimiqapp.com** in a **new private/incognito** window  
3. You should see **SwimIQ login** (same as Chrome on your PC)  
4. Sign in and click around — Dashboard, Passport, etc.

**If you still see the old short page:** press **Ctrl+F5** or clear cache.

---

# PART C — What to tell people (copy/paste)

> Try SwimIQ in your browser now (full app demo):  
> **https://swimiqapp.com**  
>  
> Create an account, explore the dashboard and Athlete Passport.  
> **Android app:** Google Play in the next few weeks.  
> **iPhone app:** App Store in September.  
>  
> Questions: **support@swimiqapp.com**

---

# When you update the Flutter app later

Every time you change the app and want the website updated:

1. `git pull`  
2. Run **`scripts\build-web-godaddy.ps1`** again  
3. Upload **all files** from `build\web` to GoDaddy `public_html` again (replace old files)

---

# Troubleshooting

| Problem | Fix |
|---------|-----|
| “SwimIQ is not connected” on swimiqapp.com | `.env` keys wrong; rebuild with script |
| Blank white page | Upload incomplete — need ALL of `build/web`, including `canvaskit` folder |
| Old page still shows | Hard refresh Ctrl+F5; wait 10 min |
| No File Manager in GoDaddy | Call GoDaddy — you may need **Web Hosting** on the domain |
| Upload fails / too big | Use **FileZilla** (FTP) — same files, same `public_html` folder |

---

# GoDaddy phone script

> “I built a web app with HTML and JavaScript files in a folder. I need to upload everything to **public_html** for swimiqapp.com. Can you help me use File Manager or FTP?”

---

# Timeline reminder

| When | What |
|------|------|
| **Now** | **swimiqapp.com** = Flutter web demo (browser) |
| **~2–3 weeks** | Android app on Google Play |
| **September** | iPhone app on App Store (with Mac laptop) |

Then add store buttons on the site — the browser demo can stay as a “try before you install” option.
