# Android launch checklist (do before Play goes live)

Use this in the last days before launch. Check items off in order.

## Blockers (must do)

- [ ] **Upload keystore created** (`CREATE-KEYSTORE.bat`) and backed up offline
- [ ] **`android/key.properties` filled in** (not committed to git)
- [ ] **Signed AAB built** with Supabase dart-defines (`BUILD-ANDROID-NOW.bat` / `build-android-release.ps1`)
- [ ] AAB installs from **Internal testing** track on a real Android phone
- [ ] App opens to login (not “SwimIQ is not connected”)
- [ ] Sign up / sign in works against **production** Supabase
- [ ] Paid plan buttons show **“Google Play billing soon”** (no free unlock of Elite/Pro)
- [ ] Elite trial + coach codes still work
- [ ] Privacy policy URL live: `https://swimiqapp.com/privacy` (or Pages URL)
- [ ] Delete-account URL live: `https://swimiqapp.com/delete-account` (upload `website/delete-account.html`)
- [ ] Play Console **Data safety** form completed
- [ ] Play Console **content rating** questionnaire completed
- [ ] Store listing: title, short/full description, screenshots, feature graphic, 512 icon
- [ ] Support email: **support@swimiqapp.com** forwards to a monitored inbox

## Strongly recommended

- [ ] Fix **HTTPS SSL** on swimiqapp.com (see [WEB_SITE_STATUS.md](WEB_SITE_STATUS.md))
- [ ] Internal testers (3–5 people) for 24–48 hours before Production
- [ ] Confirm video upload / Gemini analysis on a mid-range phone
- [ ] Confirm app label shows **SwimIQ** under the icon
- [ ] Bump `version` in `pubspec.yaml` for the store build

## Do not ship if

- Release is still signed with **debug** keys
- Mobile can **select paid plans without Play Billing**
- Supabase keys missing from the release build
- Privacy / delete-account URLs 404

## After go-live

- [ ] Add Play Store link on swimiqapp.com / marketing site
- [ ] Monitor Play Console crashes + support inbox daily for the first week
- [ ] Plan Google Play Billing for paid tiers (Stripe remains web-only until then)
