# Kara’s simple plan — website + app (read top to bottom)

## The one thing that confuses everyone (plain English)

| Thing | What it is | Where people get it |
|-------|------------|---------------------|
| **Website** | A brochure in the browser — features, updates, “coming soon” | **swimiqapp.com** (GoDaddy) |
| **Mobile app** | The real SwimIQ on a phone | **Google Play** (Android) or **App Store** (iPhone) — **not ready to install yet** |

**The website does NOT open the app today.**  
It **shows** what the app does so people get excited.  
When the app launches, we add **Download** buttons to the same website.

---

## What you tell people TODAY (copy/paste)

> Hi! SwimIQ is the app Aspyn and I are building for competitive swimmers (ages 13–30) — training log, meet results, personal bests, USA time standards, Athlete Passport, and SwimIQ AI video coaching.
>
> **See everything we’re building:** https://swimiqapp.com  
>
> **Android app:** coming in the next few weeks  
> **iPhone app:** coming September (Apple store)  
>
> Want an email when it’s ready? Write **support@swimiqapp.com** with subject **SwimIQ waitlist** and tell me Android or iPhone.
>
> — Kara

That’s a complete, honest answer. No app install link needed yet.

---

# PHASE 1 — THIS WEEK (website only)

**Goal:** When someone clicks swimiqapp.com, they see features + “coming soon” + your timeline.

### Step 1 — Get the website files on your PC

1. Open PowerShell
2. Run:
   ```powershell
   S:
   cd swimiq
   git pull
   ```
3. Open folder **`S:\swimiq\website`** in File Explorer  
   You should see `index.html`, `privacy.html`, `terms.html`, `ai.html`, and folder `css`

### Step 2 — Put them on GoDaddy (one time)

**If this feels hard, call GoDaddy and say:**  
*“Please help me upload HTML files to public_html for swimiqapp.com.”*

**If you want to try yourself:**

1. Go to **godaddy.com** → Sign in  
2. **My Products** → **swimiqapp.com** → **Manage**  
3. Open **Hosting** / **cPanel** → **File Manager**  
4. Open folder **`public_html`**  
5. Click **Upload**  
6. Upload from `S:\swimiq\website\`:
   - `index.html`
   - `privacy.html`
   - `terms.html`
   - `ai.html`
7. Create folder **`css`** inside `public_html`  
8. Upload **`site.css`** into that `css` folder  

### Step 3 — Check

Open **https://swimiqapp.com** — you should see:
- “When is the app available?”
- Android / iPhone timeline
- Feature cards
- Latest updates

**Phase 1 done.** You can text parents the link.

More detail: **docs/GODADDY_WEBSITE_UPLOAD.md**

---

# PHASE 2 — NEXT FEW WEEKS (Android app)

**Goal:** Real app on Google Play. Website gets a **Download for Android** button.

You (or help) will:
1. Build Android app from Flutter (`flutter build appbundle`)
2. Create **Google Play Developer** account ($25 one-time)
3. Upload to Play Console
4. Add link on swimiqapp.com: `https://play.google.com/store/apps/details?id=...`

**Website still on GoDaddy.** Only add one button when Play link exists.

---

# PHASE 3 — SEPTEMBER (iPhone app)

**Goal:** App on Apple App Store when you have the Mac laptop.

1. Apple Developer account ($99/year)  
2. Build on Mac → upload to App Store Connect  
3. Add **Download on the App Store** button on swimiqapp.com  

---

# What you do NOT need to worry about now

- Uploading Flutter code to GoDaddy  
- Making the website “run” the app (impossible until store links exist)  
- TestFlight (optional; September + Mac is your iPhone path)  
- Every domain — just forward .net etc. to swimiqapp.com later  

---

# Checklist (print this)

**This week**
- [ ] Pull latest code to `S:\swimiq`
- [ ] Upload `website` folder to GoDaddy `public_html`
- [ ] Open swimiqapp.com and confirm it looks right
- [ ] Set up email forward: support@swimiqapp.com → your inbox
- [ ] Send the copy/paste message above to interested parents

**Few weeks**
- [ ] Android on Google Play
- [ ] Add Android download button to website

**September**
- [ ] Mac laptop → iPhone build
- [ ] Apple App Store
- [ ] Add iPhone download button to website

---

# If GoDaddy is still confusing

**Plan B:** GoDaddy phone support (number on your account).  
**Plan C:** Ask a tech-savvy friend for 30 minutes to upload `S:\swimiq\website` to `public_html`.  
**Plan D:** Hire a one-time task on Fiverr: “Upload static HTML to GoDaddy” (~$20–50).

You already own the domain and the files are ready — it’s just **moving 5 files** to the right folder.
