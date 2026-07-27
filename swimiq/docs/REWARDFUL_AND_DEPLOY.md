# Deploy ambassadors + Rewardful (step-by-step)

This gets **Ruslan** and **Nyah** unique links live, then connects **30% commissions** through Rewardful + Stripe.

---

# PART 1 — Deploy the app update (GoDaddy)

Do this after the GitHub PR for named ambassadors is **merged into `main`**.

## 1. Update code on Kara’s Windows PC

```powershell
S:
cd \swimiq
git checkout main
git pull origin main
```

## 2. Build the GoDaddy zip

Double-click:

`S:\swimiq\SWIMIQ-BUILD-GODADDY-NOW.bat`

Wait for:

`S:\swimiq\build\swimiq-web-godaddy.zip`

## 3. Upload to GoDaddy

1. GoDaddy → **Web Hosting** → **File Manager** → **`public_html`**
2. Delete old files **except** `cgi-bin`
3. Upload `swimiq-web-godaddy.zip`
4. Extract → **Overwrite**
5. Confirm `main.dart.js` exists
6. Open **http://swimiqapp.com** in **Incognito** → SwimIQ **login**

## 4. Smoke-test ambassador links

Incognito:

1. https://swimiqapp.com/?amb=AMB-RUSLAN&via=ruslan  
2. https://swimiqapp.com/?amb=AMB-NYAH&via=nyah  

Sign up / sign in → Settings → Plans should show preview unlocked.

---

# PART 2 — Rewardful setup (30% commissions)

Rewardful watches Stripe. When someone pays after clicking an ambassador’s `?via=` link, Rewardful credits that ambassador.

## A. Create Rewardful account

1. Go to https://www.rewardful.com and sign up
2. Connect your **Stripe** account (same Stripe SwimIQ uses for Basic/Pro/Elite)
3. Use **Live mode** only when you are ready for real money (test mode first if available)

## B. Create the campaign (30%)

1. Rewardful → **Campaigns** → **New campaign**
2. Name: `SwimIQ Ambassadors`
3. Commission: **30%** recurring (recommended for subscriptions)  
   - Or 30% first invoice only — your choice
4. Cookie duration: **30–90 days** (how long after click a sale still counts)
5. Save

## C. Create affiliates Ruslan + Nyah

For **each** person:

1. Rewardful → **Affiliates** → **Invite / Add**
2. Name + their email (so they get a dashboard login)
3. Set their **token / link ID** exactly:
   - Ruslan → `ruslan`
   - Nyah → `nyah`
4. Assign them to campaign `SwimIQ Ambassadors`
5. Save

Their Rewardful links will look like:

- `https://swimiqapp.com/?via=ruslan`
- `https://swimiqapp.com/?via=nyah`

SwimIQ preferred share links (preview + via) are:

- Ruslan: `https://swimiqapp.com/?amb=AMB-RUSLAN&via=ruslan`
- Nyah: `https://swimiqapp.com/?amb=AMB-NYAH&via=nyah`

## D. Install Rewardful JavaScript on swimiqapp.com

1. Rewardful → **Campaigns** → your campaign → **Install**
2. Copy the snippet (looks like `rw.js` + `data-rewardful='…'`)
3. On Kara’s PC, open:

   `S:\swimiq\web\index.html`

4. Paste the Rewardful snippet **just before** `</head>` (or where Rewardful’s install guide says)
5. Rebuild + re-upload GoDaddy zip (Part 1 again)

Until this snippet is live, cookies may not set and commissions can miss.

## E. Confirm Stripe connection in Rewardful

1. Rewardful → **Settings → Integrations → Stripe**
2. Status should be **Connected**
3. Products: include SwimIQ Basic / Pro / Elite subscription prices
4. If Rewardful asks which Stripe events to listen for, keep subscription + checkout completed enabled

## F. Test a referral sale (Test mode first)

1. Incognito → open Nyah’s link
2. Create a throwaway account
3. Buy **Pro** (Stripe test card `4242…` if still in test mode)
4. Rewardful → **Referrals / Sales** → should show **Nyah** credited
5. Stripe Checkout session metadata should include `ambassador_referral=nyah` (SwimIQ also writes this)

When test works → switch Stripe + Rewardful to **Live** and repeat once with a real $1–small test if needed.

---

# PART 3 — Day-to-day use

## Send to ambassadors

Use the paste blocks in **`AMBASSADOR-ACCESS.md`**.

## When someone new agrees to be an ambassador

1. Pick a short slug (`jordan`, `coach-mike`, …)
2. Add them in code (`ambassador_catalog.dart`) **and** in Rewardful with the **same** slug
3. Deploy GoDaddy
4. Send: `https://swimiqapp.com/?amb=AMB-SLUG&via=slug`

Yes — **each ambassador needs their own unique link** for 30%.  
You do **not** reuse Ruslan’s link for Nyah.

## Paying them

Rewardful (or Stripe) payout settings control how ambassadors get paid (PayPal / bank). Configure that in Rewardful → Payouts once commissions start.

---

# Quick checklist

- [ ] PR merged to `main`
- [ ] GoDaddy zip rebuilt + uploaded (`main.dart.js` present)
- [ ] Ruslan + Nyah links open and unlock preview
- [ ] Rewardful account + Stripe connected
- [ ] Campaign = 30%
- [ ] Affiliates `ruslan` and `nyah` created
- [ ] Rewardful JS snippet in `web/index.html` + republished
- [ ] Test checkout attributes to the right ambassador
