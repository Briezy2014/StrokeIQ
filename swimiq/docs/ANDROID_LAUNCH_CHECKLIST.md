# Android launch checklist (do before Play goes live)

Use this in the last days before launch. Check items off in order.

**Master path on Windows:** open `PLAY-LAUNCH-KARA.md` and double-click `PLAY-LAUNCH-NOW.bat`.

## Blockers (must do)

- [ ] **Website republished** from latest `main` (Ruslan/Nyah codes + privacy pages)
- [ ] **`.env` has real Supabase** (see `FIX-ENV-FOR-PLAY.txt`) — not placeholders
- [ ] **Upload keystore created** (`GENERATE-ANDROID-KEYSTORE.bat`) and backed up offline
- [ ] **`android/key.properties` filled** (auto-written by new keystore script; gitignored)
- [ ] **Signed AAB built** (`PLAY-LAUNCH-NOW.bat` / `SWIMIQ-BUILD-AAB-NOW.bat`)
- [ ] AAB installs from **Internal testing** track on a real Android phone
- [ ] App opens to login (not “SwimIQ is not connected”)
- [ ] Sign up / sign in works against **production** Supabase
- [ ] Paid plan buttons show **“Google Play billing soon”** (no free unlock of Elite/Pro)
- [ ] Elite trial + coach codes still work (`COACH-EVAL-14`)
- [ ] Privacy policy URL live: `http://swimiqapp.com/privacy` (https after SSL fix)
- [ ] Delete-account URL live: `http://swimiqapp.com/delete-account`
- [ ] Play Console **Data safety** form completed (`PLAY-CONSOLE-FILL-THIS.txt`)
- [ ] Play Console **content rating** questionnaire completed
- [ ] Store listing: title, short/full description, screenshots, feature graphic, 512 icon
- [ ] Support email: **support@swimiqapp.com** forwards to a monitored inbox

## Strongly recommended

- [ ] Fix **HTTPS SSL** on swimiqapp.com (see [WEB_SITE_STATUS.md](WEB_SITE_STATUS.md))
- [ ] Internal testers (3–5 people) for 24–48 hours before Production
- [ ] Confirm video upload / Gemini analysis on a mid-range phone
- [ ] Confirm app label shows **SwimIQ** under the icon
- [ ] Bump `version` in `pubspec.yaml` before each new store upload

## Do not ship if

- Release is still signed with **debug** keys
- Mobile can **select paid plans without Play Billing**
- Supabase keys missing from the release build
- Privacy / delete-account URLs 404

## After go-live

- [ ] Add Play Store link on swimiqapp.com / marketing site
- [ ] Monitor Play Console crashes + support inbox daily for the first week
- [ ] Send `SEND-TO-COACHES-AND-TEAMS.txt`
- [ ] Plan Google Play Billing for paid tiers (Stripe remains web-only until then)
