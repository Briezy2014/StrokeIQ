# SwimIQ Development Roadmap

**Built in the Water. Driven by Possibility.**  
Founded by Aspyn Briez

This roadmap defines eight incremental releases. Each version ships a working product before advanced features begin. **Version 3 is the current implementation target.**

---

## Version 1 — Foundation (Complete)

**Goal:** A clean, working Android app with Supabase authentication and core swimmer data management.

| Area | Scope |
|------|-------|
| Auth | Email/password sign-up, sign-in, sign-out via Supabase Auth |
| Dashboard | SwimIQ Score, session count, personal bests, active goals, recent activity |
| Swimmer Profile | Athlete passport fields (name, team, coach, strokes, school, notes) |
| Training Log | Add/list practice and race sessions with stroke, distance, course, time |
| Meet Results | Add/list meet name, date, event, time, course |
| Goals | Add/list target events with goal time and target date |
| Charts | Time-progress line chart by stroke |
| Settings | Account email, sign out, app version |

**Out of scope for V1:** Coach dashboards, team management, cuts, IMX, wearables, AI, social sharing.

**Exit criteria:** `./gradlew assembleDebug` succeeds; user can authenticate and CRUD all core data types.

---

## Version 2 — Athlete Performance (Complete)

**Goal:** Match and exceed the Streamlit “Athlete Performance Edition” experience on mobile.

- SwimIQ Score™ algorithm (sessions, goals, PBs) with explainable breakdown
- Personal Bests screen with stroke/distance/course grouping
- Athlete Passport™ hero UI with status cards (focus event, activity summary)
- PB detection and celebration on new best times
- Formatted swim times (35.43, 1:24.32, 5:31.43) with validation helpers
- Offline read cache for dashboard and passport

**Exit criteria:** `./gradlew assembleDebug` succeeds; PB screen, score breakdown, passport hero UI, and offline cache all work.

---

## Version 3 — Coach & Team (Current)

**Goal:** Support coaches managing multiple swimmers.

- Coach role and team creation
- Roster management (invite swimmers, assign to team)
- Coach dashboard: team averages, attendance, top performers
- Bulk import of meet results (CSV)
- Push notifications for new PBs and goal deadlines

**Exit criteria:** Coach can create team, invite swimmers, view team dashboard, import CSV meet results, and receive PB/local notifications.

---

## Version 4 — Meets & Standards

**Goal:** Meet-centric workflows and USA Swimming standards.

- Meet calendar and upcoming meet planner
- Time standards / motivational cuts (B, BB, A, AA, AAA, AAAA)
- Highest cut achieved per event
- Qualifying time gap analysis (“0.8s from AA”)
- Meet heat sheet notes (manual entry)

---

## Version 5 — Advanced Metrics

**Goal:** Competitive analytics beyond raw times.

- IMX / IMR score calculation
- Readiness and training-load indicators
- Stroke rate and DPS from structured practice entries
- Season-over-season comparison charts
- Export performance report (PDF)

---

## Version 6 — Family & Sharing

**Goal:** Parents and supporters stay connected.

- Parent/guardian linked accounts (read-only or limited edit)
- Shareable Athlete Passport link (privacy-controlled)
- Achievement badges and milestone timeline
- In-app announcements from coach

---

## Version 7 — Integrations

**Goal:** Connect external data sources.

- Wearable / watch import (Garmin, Apple Health export)
- Video split tagging (manual timestamps)
- Hy-Tek / Meet Manager result import
- Cloud backup and multi-device sync polish

---

## Version 8 — Intelligence & Platform

**Goal:** AI-assisted coaching insights and platform maturity.

- AI race strategy and taper suggestions (explainable, coach-approved)
- Anomaly detection (fatigue, plateau alerts)
- Custom dashboards and widgets
- Public API for club integrations
- iOS companion app (shared Supabase backend)

---

## Technical Stack (Versions 1–2)

| Layer | Choice |
|-------|--------|
| Mobile | Kotlin, Jetpack Compose, Material 3 |
| Backend | Supabase (Auth, Postgres, Row Level Security) |
| Charts | Vico (Compose) |
| CI | Gradle `assembleDebug` / `assembleRelease` |

## Branching & Releases

- `main` — stable
- `cursor/swimiq-v1-android-2dd0` — Version 1 Android implementation
- Future versions: `cursor/swimiq-v{N}-<feature>-2dd0`

---

*© 2026 SwimIQ · Founded by Aspyn Briez*
