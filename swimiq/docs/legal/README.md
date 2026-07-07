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
