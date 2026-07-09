# Stripe setup for SwimIQ (website + demo account)

**Important:** Never put your bank routing/account number in code or Git.  
Enter Bluevine details **only** inside the Stripe Dashboard when Stripe asks.

---

## What you have today

| Piece | Status |
|-------|--------|
| swimiqapp.com (Flutter web) | Live |
| Stripe account (sandbox) | You’re setting this up |
| App charges money | After Supabase + Stripe deploy (below) |
| Coach demo login | `demo@swimiqapp.com` / `SwimIQ` (after you create the user) |

---

# PART A — Stripe Dashboard (you do this)

## 1. Finish sandbox setup

1. Stay in **Test mode** (sandbox) until testing works.
2. **Settings → Business details** — SwimIQ, Kara Williams, Groveport OH.

## 2. Connect bank (when going LIVE only)

1. **Settings → Payouts → Add bank account**
2. Enter Bluevine details **yourself** in Stripe (do not send routing/account in chat):
   - Bank: Bluevine
   - Routing: (from your Bluevine app)
   - Account: (from your Bluevine app)
3. Complete **Activate payments** when ready for real money.

## 3. Create subscription products (Test mode)

**Product catalog → Add product** — create 3 products:

| Product | Monthly | Annual |
|---------|---------|--------|
| SwimIQ Basic | $4.99/mo | $39.99/yr |
| SwimIQ Pro | $9.99/mo | $89.99/yr |
| SwimIQ Elite | $19.99/mo | $149.99/yr |

Each product: **Recurring** → add **monthly** price, then **yearly** price.

## 4. Copy Price IDs

Each price has an ID like `price_1ABC...`. Copy all **6** IDs.

**Your sandbox Price IDs (test mode):**

| Secret name | Price ID |
|-------------|----------|
| `STRIPE_PRICE_BASIC_MONTHLY` | `price_1TqfCpAGTU3uDC7zn2vtpFFO` |
| `STRIPE_PRICE_BASIC_ANNUAL` | `price_1TqfEGAGTU3uDC7ziSbknFdT` |
| `STRIPE_PRICE_PRO_MONTHLY` | `price_1TqfIIAGTU3uDC7zJkgA90xR` |
| `STRIPE_PRICE_PRO_ANNUAL` | `price_1TqfJ2AGTU3uDC7zlYPp9evf` |
| `STRIPE_PRICE_ELITE_MONTHLY` | `price_1TqfK8AGTU3uDC7zaL5Zj3UQ` |
| `STRIPE_PRICE_ELITE_ANNUAL` | `price_1TqfLCAGTU3uDC7zSrjzvNuW` |

---

# PART B — Supabase (database + secrets)

## 1. Run migration

Supabase Dashboard → **SQL Editor** → run:

`supabase/migrations/004_user_subscriptions.sql`

## 2. Add Edge Function secrets

**Project Settings → Edge Functions → Secrets** — add:

| Secret | Value |
|--------|--------|
| `STRIPE_SECRET_KEY` | Stripe → Developers → API keys → **Secret key** (test) |
| `STRIPE_WEBHOOK_SECRET` | From webhook setup (Part C) |
| `STRIPE_PRICE_BASIC_MONTHLY` | `price_...` |
| `STRIPE_PRICE_BASIC_ANNUAL` | `price_...` |
| `STRIPE_PRICE_PRO_MONTHLY` | `price_...` |
| `STRIPE_PRICE_PRO_ANNUAL` | `price_...` |
| `STRIPE_PRICE_ELITE_MONTHLY` | `price_...` |
| `STRIPE_PRICE_ELITE_ANNUAL` | `price_...` |
| `STRIPE_SUCCESS_URL` | `https://swimiqapp.com/?checkout=success` |
| `STRIPE_CANCEL_URL` | `https://swimiqapp.com/?checkout=cancel` |

(You should already have `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY`.)

## 3. Deploy Edge Functions

From a machine with Supabase CLI linked to your project:

```bash
cd swimiq
supabase functions deploy create-stripe-checkout
supabase functions deploy stripe-webhook
```

---

# PART C — Stripe webhook

1. Stripe Dashboard → **Developers → Webhooks → Add endpoint**
2. URL:
   ```
   https://YOUR_PROJECT_REF.supabase.co/functions/v1/stripe-webhook
   ```
3. Events:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
4. Copy **Signing secret** → paste as `STRIPE_WEBHOOK_SECRET` in Supabase.

---

# PART D — Coach demo master account

## 1. Create auth user

Supabase → **Authentication → Users → Add user**

| Field | Value |
|-------|--------|
| Email | `demo@swimiqapp.com` |
| Password | `SwimIQ` |
| Auto-confirm | Yes |
| Metadata | `{"display_name":"SwimIQ Demo"}` |

## 2. Grant Elite access

SQL Editor → run `supabase/seed_demo_master.sql`

## 3. Login on swimiqapp.com

Click **Coach demo login** or sign in with:

- **Email:** `demo@swimiqapp.com`
- **Password:** `SwimIQ`

Change the password in Supabase after your first demo if you want.

---

# PART E — Test payments (sandbox)

1. `git pull` → rebuild web → upload to GoDaddy (same as before).
2. Sign in on **swimiqapp.com**
3. **Settings → Plans & billing** → pick **Elite**
4. Stripe test card: `4242 4242 4242 4242`, any future date, any CVC
5. After payment, you return to SwimIQ with `?checkout=success` and plan shows **Active**

---

# PART F — Go live

1. Stripe: complete business verification + add Bluevine bank
2. Toggle **Live mode** in Stripe
3. Create the same 3 products in **Live mode** — copy new Price IDs
4. Update Supabase secrets with **live** keys and live Price IDs
5. Add a **live** webhook endpoint (same URL, live signing secret)

---

# Android note

Google Play requires **Play Billing** for in-app subscriptions.  
**Stripe on swimiqapp.com** works for browser users now.

**v1 Android launch:** Elite trial + coach preview codes only — paid plan buttons are disabled in the app until Google Play Billing ships. See `docs/ANDROID_RELEASE.md` and `lib/core/subscription/subscription_billing_policy.dart`.

---

# Need help?

Email in app: **support@swimiqapp.com**
