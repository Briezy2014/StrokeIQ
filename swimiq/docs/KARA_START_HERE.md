# Kara’s simple plan — website + app (read top to bottom)

## Start here this week

1. **Website broken on https?** → Read **[WEB_SITE_STATUS.md](WEB_SITE_STATUS.md)** and fix GoDaddy SSL first.  
2. **Want auto browser app?** → **[WEB_DEPLOY.md](WEB_DEPLOY.md)** (GitHub Pages + Actions).  
3. **Android in a few days?** → **[ANDROID_LAUNCH_CHECKLIST.md](ANDROID_LAUNCH_CHECKLIST.md)** + **[ANDROID_RELEASE.md](ANDROID_RELEASE.md)**.

---

## The one thing that confuses everyone (plain English)

| Thing | What it is | Where people get it |
|-------|------------|---------------------|
| **Website app** | The **real SwimIQ Flutter app** in Chrome/Safari | **swimiqapp.com** (GoDaddy) or GitHub Pages after setup |
| **Brochure pages** | Optional features/legal HTML in `website/` | Only if you upload those files **alongside** the Flutter build |
| **Mobile app** | SwimIQ on a phone | **Google Play** (Android soon) / **App Store** (iPhone later) |

**Parents should be able to log in and click around in the browser.**  
That means uploading **`build/web`** (Flutter), not only the small `website/` folder.

---

## What you tell people TODAY (copy/paste)

> Hi! SwimIQ is the app Aspyn and I are building for competitive swimmers — training log, meet results, personal bests, USA time standards, Athlete Passport, and SwimIQ AI video coaching.
>
> **Try it in your browser:** https://swimiqapp.com  
>
> **Android app:** launching on Google Play soon  
> **iPhone app:** coming later (App Store)  
>
> Want an email when the phone app is ready? Write **support@swimiqapp.com** with subject **SwimIQ waitlist** and say Android or iPhone.
>
> — Kara

If https shows a security warning, tell them to use **http://swimiqapp.com** until SSL is fixed (see WEB_SITE_STATUS.md).

---

# PHASE 1 — WEBSITE = FLUTTER APP IN THE BROWSER

**Goal:** https://swimiqapp.com opens SwimIQ login (no certificate warning).

1. Fix SSL — **[WEB_SITE_STATUS.md](WEB_SITE_STATUS.md)**  
2. Build + upload Flutter web — **[WALKTHROUGH_SWIMIQAPP_COM.md](WALKTHROUGH_SWIMIQAPP_COM.md)**  
3. Optional backup URL — **[WEB_DEPLOY.md](WEB_DEPLOY.md)**

```powershell
S:
cd swimiq
git pull origin main
powershell -ExecutionPolicy Bypass -File scripts\build-web-godaddy.ps1
```

Upload **everything inside** `build\web\` to GoDaddy **`public_html`**.

Also upload legal helpers if missing:
- `website/privacy.html`, `terms.html`, `ai.html`, `delete-account.html`

---

# PHASE 2 — ANDROID (NEXT FEW DAYS)

**Goal:** Signed app on Google Play Internal testing → Production.

1. Create keystore: `CREATE-KEYSTORE.bat`  
2. Fill `android/key.properties`  
3. Build AAB: `BUILD-ANDROID-NOW.bat`  
4. Follow **[ANDROID_LAUNCH_CHECKLIST.md](ANDROID_LAUNCH_CHECKLIST.md)**

Paid subscriptions on the phone wait for Google Play Billing. Trial + coach codes work now. Stripe stays on the website.

---

# PHASE 3 — IPHONE (LATER)

Needs Mac + Apple Developer account. See **[TESTFLIGHT.md](TESTFLIGHT.md)**.

---

# Checklist (print this)

**Website**
- [ ] Trusted SSL on swimiqapp.com (not self-signed)
- [ ] Flutter `build/web` on `public_html`
- [ ] Incognito: login screen loads on **https**
- [ ] support@swimiqapp.com forwards to your inbox
- [ ] (Optional) GitHub Pages Flutter deploy live

**Android**
- [ ] Keystore + key.properties
- [ ] Signed AAB with Supabase keys
- [ ] Internal testing pass
- [ ] Privacy + delete-account URLs work
- [ ] Production release

---

# If GoDaddy is confusing

Call GoDaddy and say:  
*“Please install a trusted SSL certificate for swimiqapp.com and help me confirm public_html is serving my uploaded files.”*
