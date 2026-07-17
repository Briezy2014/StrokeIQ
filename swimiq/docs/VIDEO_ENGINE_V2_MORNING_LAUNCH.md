# Elote Video Lab (V2) — Morning Launch Checklist

Use this when you wake up. Follow the steps in order. Rollback is at the bottom.

## What was verified overnight

- Backend pytest suite: green after security/allowlist guards
- Flutter suite: Aspyn Video Lab widget crash fixed (`currentUserProvider` safe before Supabase init)
- Dual-run flag now shows a **Run legacy analysis** action for allowlisted users when `VIDEO_ENGINE_V2_DUAL_RUN=true`
- Video playback prefers signed URLs (private `swim-videos` bucket)
- New migration `007_drop_legacy_open_video_policies.sql` drops open-table policies
- Backend mirrors Flutter allowlist via `VIDEO_ENGINE_V2_ALLOWLIST`
- Create-job rejects `local_path` when `SUPABASE_AUTH_REQUIRED=true` and checks storage ownership

## Known limitations (do not block a limited allowlist launch)

1. Persisted Supabase jobs may appear in history but status/results still prefer the local JSON store — keep one analysis API instance for now, or accept restart gaps.
2. Legacy docs (`GEMINI_SETUP.md`, root README) still describe the Edge Function path; V2 env is in `swimiq/.env.example` and `services/video_analysis/.env.example`.

---

## Step 1 — Apply Supabase migrations

In order:

1. `swimiq/supabase/migrations/005_video_analysis_engine_v2.sql` (if not already applied)
2. `swimiq/supabase/migrations/006_swim_videos_private_storage.sql`
3. `swimiq/supabase/migrations/007_drop_legacy_open_video_policies.sql`

Verify in Supabase SQL editor:

```sql
SELECT policyname FROM pg_policies
WHERE tablename IN ('swim_videos', 'swim_video_analyses')
ORDER BY tablename, policyname;
```

Confirm `swim_videos_all` / `swim_video_analyses_all` are gone.

Optional but recommended: backfill ownership on older rows you care about:

```sql
-- Only if you know how to map swimmer → auth user; adjust before running.
-- UPDATE public.swim_videos SET user_id = '<uuid>' WHERE user_id IS NULL AND ...;
```

---

## Step 2 — Start / configure the analysis backend

Working directory: `services/video_analysis`

Set at least:

```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
SUPABASE_AUTH_REQUIRED=true
SUPABASE_PERSIST_RESULTS=true
POSE_ENABLED=true
GEMINI_REPORT_ENABLED=true
GEMINI_API_KEY=YOUR_GEMINI_KEY
VIDEO_ENGINE_V2_ALLOWLIST=you@example.com
CORS_ALLOW_ORIGINS=*
```

Also ensure detector/pose model paths and `FFMPEG_PATH` / `FFPROBE_PATH` are valid for this machine.

Start the API (example):

```bash
cd services/video_analysis
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

Smoke check:

```bash
curl -s http://localhost:8080/health
```

---

## Step 3 — Configure Flutter (no secrets beyond anon)

Edit `swimiq/.env`:

```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
ANALYSIS_API_BASE_URL=http://YOUR_API_HOST:8080
VIDEO_ENGINE_V2=true
VIDEO_ENGINE_V2_ALLOWLIST=you@example.com
VIDEO_ENGINE_V2_DUAL_RUN=false
```

Rules:

- Never put `GEMINI_API_KEY` or `SUPABASE_SERVICE_ROLE_KEY` in Flutter.
- Keep allowlist **non-empty** for first launch (empty + V2 on = all users).
- Set the same allowlist emails on backend `VIDEO_ENGINE_V2_ALLOWLIST`.
- Set `VIDEO_ENGINE_V2_DUAL_RUN=true` only if you want a **Run legacy analysis** button next to V2 for allowlisted accounts.

---

## Step 4 — Run the app and verify the Video tab

```bash
cd swimiq
flutter pub get
flutter run
```

Sign in as an allowlisted email, open the **Video** tab, and confirm:

1. Header reads **Elote Video Lab** (not plain Video Lab)
2. Existing clips still preview (signed playback)
3. Upload a short MP4 → storage path is `{userId}/...`
4. **Run Elote Analysis** opens the V2 setup sheet → progress → results
5. Metrics show values or “Unavailable” — never invented zeros
6. Coaching narrative may say unavailable if Gemini is down; metrics still show
7. History screen lists the job
8. Non-allowlisted account still sees **Video Lab** + legacy path

---

## Step 5 — Quick regression commands (optional)

```bash
cd services/video_analysis && pytest -q
cd swimiq && flutter test test/video_engine_v2_test.dart test/aspyn_screen_widget_test.dart
```

---

## Rollback (immediate)

Flutter `.env`:

```env
VIDEO_ENGINE_V2=false
```

Restart the app. Everyone returns to the legacy Edge Function analysis path. Leave the backend and migrations in place; they are inert when the flag is off.

If dual-run is on and only V2 is misbehaving, use **Run legacy analysis** without flipping the global flag.

---

## Do not do this morning

- Do not delete the legacy `analyze-swim-video` Edge Function
- Do not put Gemini / service-role keys in Flutter
- Do not open allowlist to everyone until one real video end-to-end pass succeeds
- Do not start Milestone 10 redesign work during launch
