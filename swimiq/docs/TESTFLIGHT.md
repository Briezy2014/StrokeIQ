# SwimIQ TestFlight — invite parents & beta testers

Use this when a parent says *“We want to try it!”* and your swimmers are **13+** (they create their own account).

**Bundle ID:** `com.swimiq.swimiq`  
**App name on phone:** SwimIQ  
**You need:** Apple Developer Program (**$99/year**) — [developer.apple.com/programs](https://developer.apple.com/programs/)

---

## Big picture (3 steps)

1. **Build** the iOS app (`.ipa`) with your Supabase keys baked in  
2. **Upload** to App Store Connect  
3. **Invite** testers by email in TestFlight (or share a public link)

**Windows note:** You cannot upload to TestFlight from Windows alone. You need **one** of:
- A **Mac** with Xcode (borrow, school, or library), **or**
- **Codemagic** (free tier) — builds in the cloud from your GitHub repo

---

## Step 0 — One-time Apple setup

### A. Enroll in Apple Developer Program
1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Enroll as **Individual** (Kara Jayne Williams) or **Organization** (SwimIQ LLC after you file)
3. Pay **$99/year**, wait for approval (usually 24–48 hours)

### B. Create the app in App Store Connect
1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → **+** → **New App**
2. **Platform:** iOS  
3. **Name:** SwimIQ  
4. **Primary language:** English (U.S.)  
5. **Bundle ID:** `com.swimiq.swimiq` (create in [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) if missing)  
6. **SKU:** `swimiq-ios` (any unique string)

### C. Privacy (required for TestFlight external testing)
- **Privacy Policy URL:** For now use in-app policy; ideally host English text at a URL you control.  
  *(swimiq.app currently shows a different Turkish app — fix domain or use another URL before App Store submission.)*
- In App Store Connect → your app → **App Privacy** → fill questionnaire to match `assets/legal/privacy_policy.txt`

---

## Step 1 — Build the iOS app

Supabase keys **must** be in the build. `.env` is **not** shipped on iOS unless you pass `--dart-define`.

### On a Mac (from your `swimiq` folder)

```bash
cd swimiq
flutter pub get
flutter build ipa \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Output: `build/ios/ipa/swimiq.ipa`

**Or** use the script (edit keys first):

```bash
./scripts/build-ios-testflight.sh
```

### Upload from Mac (easiest)

1. Open **`build/ios/archive/Runner.xcarchive`** in Xcode **Organizer**, **or**
2. Use **Transporter** app (Mac App Store) → drag `swimiq.ipa` → **Deliver**

### From Windows (Codemagic)

1. Push repo to GitHub  
2. Sign up at [codemagic.io](https://codemagic.io) → connect repo  
3. Add environment variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY`  
4. Add App Store Connect API key (see Codemagic iOS docs)  
5. Run workflow → auto-upload to TestFlight  

*(See `codemagic.yaml` in this repo when added.)*

---

## Step 2 — Wait for processing

App Store Connect → **TestFlight** → build shows **Processing** (10–30 min), then **Ready to Test**.

Fill **Export Compliance** when asked: SwimIQ uses HTTPS only → typically **No** for custom encryption.

---

## Step 3 — Invite testers

### Option A — Email invite (best for one parent)

1. App Store Connect → **TestFlight** → **External Testing** (or **Internal** if they’re on your team)  
2. Create group e.g. **“Parent beta”**  
3. Add build **1.0.0 (1)**  
4. **Add testers** → enter parent’s **Apple ID email**  
5. They get email → install **TestFlight** app from App Store → **Accept** → **Install SwimIQ**

**First external build:** Apple **Beta App Review** (~24–48 hours). Internal testing (your Apple ID only) skips this.

### Option B — Public link (many families)

TestFlight → External group → enable **Public Link** → copy link → text to parents.

---

## Step 4 — What to tell the parent (13+)

Copy/paste:

> Hi! Here’s the SwimIQ beta invite:
>
> 1. Install Apple’s **TestFlight** app from the App Store (free).  
> 2. Open the invite link I sent / check email from Apple TestFlight.  
> 3. Tap **Accept**, then **Install SwimIQ**.  
> 4. Open SwimIQ → **Create account** with your swimmer’s email.  
> 5. Fill in **Athlete Passport** (birthday + gender for USA age-group cuts).  
> 6. Add **meet results** on the Meets tab.  
>
> Privacy Policy: **Settings → Legal & privacy** inside the app.  
> Questions: **support@swimiq.app**

---

## Each new upload (bug fixes)

1. Bump version in `pubspec.yaml`: e.g. `1.0.0+1` → `1.0.0+2` (the `+2` is build number)  
2. Rebuild IPA  
3. Upload again  
4. TestFlight auto-notifies testers who had the old build

---

## Checklist before first invite

- [ ] Apple Developer enrolled ($99)  
- [ ] App created in App Store Connect (`com.swimiq.swimiq`)  
- [ ] Supabase Email auth enabled  
- [ ] IPA built with `--dart-define` Supabase keys  
- [ ] Build uploaded and **Ready to Test**  
- [ ] Beta App Review passed (external testers)  
- [ ] Parent email added or public link copied  

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| App says “not connected” on phone | Rebuild with `--dart-define=SUPABASE_URL` and `SUPABASE_ANON_KEY` |
| No invite email | Check spam; Apple ID email must match |
| “Unable to install” | iOS version too old; need iOS 13+ (Flutter default) |
| Upload fails signing | Open `ios/Runner.xcworkspace` in Xcode → **Signing & Capabilities** → Team = your Apple Developer account |

---

## Need help?

- Apple TestFlight help: [developer.apple.com/testflight](https://developer.apple.com/testflight)  
- Free business mentor: [score.org](https://www.score.org)
