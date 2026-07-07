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
  - https://swimiq.app/privacy
  - https://swimiq.app/terms
  - https://swimiq.app/ai

Host the **same text** on your website when `swimiq.app` is live. Until then, in-app copies are the source of truth.

## Operator (Ohio)

- **Operator:** SwimIQ
- **Address:** 199 Harbinger Dr., Groveport, OH 43125
- **Governing law:** Ohio
- **privacy@swimiq.app** / **support@swimiq.app**

Update `legal_constants.dart` and the three `.txt` files together when anything changes.

## Ownership plan (Ohio)

**Now (before Aspyn is 18):** You (parent/guardian) should be the legal operator — not Aspyn’s name on Privacy Policy or Terms. She can be the featured athlete in the product; liability and COPPA consent stay with you.

**Recommended entity:** Form **SwimIQ LLC** in Ohio (~$99) when you are close to App Store launch or first paid users — not required on day one, but it separates your personal assets from app liability. You can be the sole **Managing Member** now.

**When Aspyn turns 18:** Update legal docs to name **Aspyn Briez Williams** as operator (or **Managing Member of SwimIQ LLC**). Steps:
1. Amend Ohio LLC operating agreement (add Aspyn as member/manager if using LLC)
2. Replace operator name in `legal_constants.dart` and all three `assets/legal/*.txt` files
3. Update App Store Connect “seller” / business info if needed
4. Bump `lastUpdated` date and republish web copies at swimiq.app

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
3. Mirror the same text on swimiq.app when hosted
4. Run `flutter test` (assets are bundled at build time)
