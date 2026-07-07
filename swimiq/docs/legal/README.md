# SwimIQ Legal Documents

## Where everything lives

| What | Path | How users open it |
|------|------|-------------------|
| Privacy Policy | `assets/legal/privacy_policy.txt` | **Settings → Legal & privacy → Privacy Policy** |
| Terms of Service | `assets/legal/terms_of_service.txt` | **Settings → Legal & privacy → Terms of Service** |
| AI & Data Disclosure | `assets/legal/ai_data_disclosure.txt` | **Settings → Legal & privacy → AI & Data Disclosure** |
| Metadata (emails, address, URLs) | `lib/core/constants/legal_constants.dart` | Used by Settings, footer, AI consent |
| In-app reader | `lib/screens/legal/legal_document_screen.dart` | Loads the `.txt` files from the app bundle |

There are **three** legal documents in the app today — not dozens. Other docs (subscription addendum, health disclaimer, etc.) can be added later as new `.txt` files under `assets/legal/` and linked from Settings.

## In-app vs web links

- **In-app:** Full text is bundled inside the app. Works offline. Tap **Settings → Legal & privacy**.
- **Web (App Store):** Apple wants a public URL. Settings also lists:
  - https://swimiqapp.com/privacy
  - https://swimiqapp.com/terms
  - https://swimiqapp.com/ai

Host the **same text** on **swimiqapp.com** at `/privacy`, `/terms`, and `/ai`.

**Website source (upload to GoDaddy):** `swimiq/website/` — see `website/README.md`.  
Run `python3 website/sync_legal.py` after editing legal `.txt` files to refresh HTML pages.

## Operator (Ohio)

- **Operator:** Kara Jayne Williams (SwimIQ)
- **Address:** 199 Harbinger Dr., Groveport, OH 43125
- **Governing law:** Ohio
- **privacy@swimiqapp.com** / **support@swimiqapp.com**
- **Planned LLC name:** SwimIQ LLC
- **Planned owner at Aspyn’s 18th birthday:** Aspyn Briez Williams

Update `legal_constants.dart` and the three `.txt` files together when anything changes.

## How to form SwimIQ LLC in Ohio (Kara’s checklist)

**Cost:** **$99** state filing fee (Ohio has **no annual report** fee for LLCs — a big plus).

**Official portal:** [Ohio Business Central](https://bsportal.ohiosos.gov/) (Ohio Secretary of State)

### Step-by-step (~30 minutes online)

1. **Name search** — Confirm **SwimIQ LLC** is available (must include “LLC” or “Limited Liability Company”). Search at [Ohio business name search](https://bsportal.ohiosos.gov/).

2. **Create account** on Ohio Business Central → **File a new business** → **Limited Liability Company (Ohio)** (Form 610 Articles of Organization).

3. **Fill in the form:**
   - **LLC name:** `SwimIQ LLC`
   - **Purpose:** general (software / mobile app is fine)
   - **Statutory agent:** **Kara Jayne Williams** at **199 Harbinger Dr., Groveport, OH 43125** (you can be your own agent in Ohio — free)
   - **Management:** Member-managed (you as sole member/manager)
   - **Organizer:** Kara Jayne Williams

4. **Pay $99** online (credit card).

5. **Wait for approval** — usually **3–7 business days** (faster online). You’ll get stamped Articles of Organization — **save the PDF**.

6. **Get a free EIN** from the IRS (required before App Store business banking): [irs.gov/ein](https://www.irs.gov/businesses/small-businesses-self-employed/apply-for-an-employer-identification-number-ein-online) — choose LLC, Ohio, your name as responsible party.

7. **Operating agreement** (keep at home, not filed with state) — one-page doc saying:
   - Kara Jayne Williams = 100% owner / Managing Member until amended
   - Note: Aspyn Briez Williams may receive membership interest at age 18 (ChatGPT can draft from this sentence)

8. **After LLC is approved** — update legal docs from “Kara Jayne Williams” to **“SwimIQ LLC”** (managed by Kara Jayne Williams) in `legal_constants.dart` and all three `assets/legal/*.txt` files.

9. **Optional:** Open a **business bank account** (Chase, local credit union) using EIN + Articles of Organization — keeps app money separate from personal.

10. **App Store Connect** — when you sell subscriptions, register seller as **SwimIQ LLC** with EIN.

### What you do NOT need right away

- Lawyer to file ($99 DIY is normal in Ohio)
- Notarization for Articles of Organization
- Trademark (later, ~$250+ USPTO if you want federal protection)

### Free help (Ohio)

- **Akron SEED Clinic** — low-cost help for small businesses under $100k revenue: [uakron.edu SEED Clinic](https://www.uakron.edu/law/curriculum/clinical-programs/seed-clinic)
- **SCORE** — free mentor: [score.org](https://www.score.org)

## Ownership plan (Ohio)

**Now (before LLC is filed):** Legal docs say **Kara Jayne Williams · SwimIQ**.

**After LLC is filed:** Change to **SwimIQ LLC** (Managing Member: Kara Jayne Williams).

**Now (before Aspyn is 18):** Kara remains legal operator — not Aspyn’s name on Privacy Policy or Terms.

**When Aspyn turns 18:** Update legal docs to name **Aspyn Briez Williams** as operator (or **Managing Member of SwimIQ LLC**). Steps:
1. Amend Ohio LLC operating agreement (add Aspyn as member/manager if using LLC)
2. Replace operator name in `legal_constants.dart` and all three `assets/legal/*.txt` files
3. Update App Store Connect “seller” / business info if needed
4. Bump `lastUpdated` date and republish web copies at swimiqapp.com

**Planned owner name at 18:** Aspyn Briez Williams

**Optional now:** In-app footer can stay “© SwimIQ” until transition; at 18 you may use “© SwimIQ · Aspyn Briez Williams” or “Operated by Aspyn Briez Williams.”

## Product audience

- Athletes **ages 8 through 30**
- **Ages 8–12:** parent/guardian account + consent (COPPA)
- **Ages 13–30:** athlete may use own account

## Also shown in the app

- **Membership** screen — `LegalFooter` links to all three docs
- **Video Lab** — AI consent dialog before first analysis (uses `ai_data_consent_dialog.dart`)

## After you edit a legal file

1. Save the `.txt` under `assets/legal/`
2. Bump `lastUpdated` in `legal_constants.dart` if the date changed
3. Mirror the same text on swimiqapp.com when hosted
4. Run `flutter test` (assets are bundled at build time)
