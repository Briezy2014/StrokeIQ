# SwimIQ

**Built in the Water. Driven by Possibility.**  
Founded by Aspyn Briez

SwimIQ is a swim performance platform. **Version 3 (Coach & Team)** is the current Kotlin Android app.

See the full product plan in [docs/ROADMAP.md](docs/ROADMAP.md) (Versions 1–8).

## Version 3 — Coach & Team (Kotlin Android)

### Features

- Everything in V1 (auth, training, meets, goals, charts) and V2 (PBs, Passport, score breakdown, offline cache)
- **Coach role** — switch between Swimmer and Coach in Settings
- **Team creation** — coaches create teams and invite swimmers by email
- **Roster management** — pending invites auto-link when swimmers sign up
- **Coach dashboard** — team avg SwimIQ, attendance, top performers
- **CSV bulk import** — import meet results for roster swimmers
- **Notifications** — in-app alerts for PBs; upcoming goal deadlines; local Android notifications on new PBs

A Flutter reference app also lives in [`swimiq/`](swimiq/).

### Supabase setup

1. Run [supabase/migrations/001_swimiq_v1.sql](supabase/migrations/001_swimiq_v1.sql)
2. Run [supabase/migrations/002_swimiq_v3_coach_team.sql](supabase/migrations/002_swimiq_v3_coach_team.sql)
3. Enable Email auth in Supabase

### Android setup

```bash
cp android/local.properties.example android/local.properties
# Edit sdk.dir, SUPABASE_URL, SUPABASE_KEY
cd android
./gradlew test assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

### Coach workflow

1. Sign up / sign in
2. Settings → **Switch to Coach**
3. Coach tab → **Create Team**
4. **Invite Swimmer** by email
5. Swimmer signs up with that email → auto-joins roster
6. View team analytics and **Import Meet Results (CSV)**

CSV format: `swimmer_name,meet_name,meet_date,event,swim_time,course`

---

© 2026 SwimIQ · Founded by Aspyn Briez
