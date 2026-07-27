# Play launch — Kara do-this list (2 days)

This cloud environment **cannot** install Android SDK, open Play Console, or install on a phone.  
Everything below is prepared in the repo for you to run on the Windows PC.

## A. Fix website first (so links + privacy work)

Live site was still an **old** build (no Ruslan/Nyah codes). Do this before sending coaches:

```powershell
S:
cd \swimiq
git checkout main
git pull origin main
```

Double-click `SWIMIQ-BUILD-GODADDY-NOW.bat` → upload zip to GoDaddy `public_html` (keep `cgi-bin`).

Test:
- http://swimiqapp.com  → login
- http://swimiqapp.com/privacy
- http://swimiqapp.com/delete-account
- http://swimiqapp.com/?amb=AMB-RUSLAN&via=ruslan

Use **http://** until SSL is fixed.

## B. Android signed AAB (must do)

1. Fix `.env` → open `FIX-ENV-FOR-PLAY.txt` and paste real Supabase anon key  
2. Double-click **`GENERATE-ANDROID-KEYSTORE.bat`** once (backup `.jks` + password)  
3. Double-click **`PLAY-LAUNCH-NOW.bat`**  
4. Upload `build\app\outputs\bundle\release\app-release.aab` to **Internal testing**

## C. Play Console forms

Open **`PLAY-CONSOLE-FILL-THIS.txt`** and paste:
- Store listing text
- Data safety answers
- Content rating guidance
- Screenshot checklist

## D. Phone confirmation

Internal testing link → install → must open **login**, not “not connected”.  
Redeem `COACH-EVAL-14`. Paid buttons should say Google Play billing soon.

## E. Outreach

Send copy from **`SEND-TO-COACHES-AND-TEAMS.txt`**.

## Already done in GitHub `main`

- Ruslan / Nyah ambassador codes + referral metadata hook
- Coach codes
- Privacy / delete-account pages in web build pipeline
- Android billing gate for Play review
- One-of-a-kind Passport features (after you republish web)
