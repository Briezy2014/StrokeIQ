# SwimIQ

**Built in the Water. Driven by Possibility.**  
Founded by Aspyn Briez

SwimIQ is a swim performance platform. **Version 4 (Meets & Standards)** is the current Kotlin Android app.

See [docs/ROADMAP.md](docs/ROADMAP.md) for Versions 1–8.

## Version 4 — Meets & Standards

### New in V4

- **USA Swimming 2024–2028 Motivational Standards** — 1,008 SCY age-group cuts (B through AAAA) bundled from official PDF
- **Cuts tab** — highest cut per personal best with gap analysis (e.g. `0.41s from AA`)
- **Meet Planner** — upcoming meet calendar with location and notes
- **Heat sheet notes** — heat/lane/event notes per planned meet
- **Athlete Passport** — shows highest motivational cut achieved

### Supabase setup

1. `supabase/migrations/001_swimiq_v1.sql`
2. `supabase/migrations/002_swimiq_v3_coach_team.sql`
3. `supabase/migrations/003_swimiq_v4_meets_standards.sql`

### Build & run

```bash
cp android/local.properties.example android/local.properties
cd android && ./gradlew test assembleDebug
```

### Standards data

Source: USA Swimming 2024–2028 Motivational Age Group Standards (SCY).  
Bundled asset: `android/app/src/main/assets/usa_2028_motivational_standards.json`

---

© 2026 SwimIQ · Founded by Aspyn Briez
