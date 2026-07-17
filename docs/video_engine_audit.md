# SwimIQ Video Analysis Engine — Phase 1 Audit

**Status:** Read-only audit complete. No application code was modified.  
**Date:** 2026-07-16  
**Repo:** `Briezy2014/StrokeIQ`  
**Scope:** Current Video Lab / Gemini / MediaPipe pipeline under `swimiq/` and related root artifacts.  
**Destination product name:** **Elote Video Lab** (rebuild; do not continue patching the Gemini–MediaPipe measurement path).

---

## Executive verdict

The live analysis path is:

**Flutter Video Lab → Supabase Storage (`swim-videos`) → Edge Function `analyze-swim-video` → Gemini 2.0 Flash (full-video inline base64) → narrative coaching JSON → `swim_video_analyses`.**

There is **no working production pose engine**. MediaPipe / BlazePose implementations are stubs (`isSupported = false` on web, IO, and stub). Pose math utilities remain as orphaned Dart code.

The pipeline feels broken primarily because:

1. Gemini is used as the **measurement and coaching engine** on the whole video (violates the new architecture).
2. Failures often fall through to a **notes-only V1 report** that still surfaces as **“AI analysis saved.”**
3. Hard **~18 MB** inline Gemini limit rejects many phone race clips.
4. Open RLS + public bucket + service-role download without ownership checks create security and reliability gaps.
5. Docs still claim MediaPipe pose on Chrome; code contradicts this.

**Decision for rebuild:** Preserve the Flutter app shell, auth, Supabase integration, upload UX foundations, subscriptions, and non-video features. Replace only the analysis engine with an isolated Python FastAPI service using **RTMPose WholeBody + RTMDet + OpenCV + FFmpeg + deterministic biomechanics + Gemini for narrative only**.

---

## 1. Current Flutter video upload flow

### Entry points

| UI | Path | Notes |
|----|------|-------|
| Bottom nav tab | `swimiq/lib/screens/home_screen.dart` | Label: **Video** (`HomeTab.videoLab`) |
| Screen | `swimiq/lib/screens/video_lab/video_lab_screen.dart` | Header title: **Video Lab** |
| Passport hub CTA | `swimiq/lib/widgets/passport_hub.dart`, `passport_ai_recommendation.dart` | Deep-links into Video Lab |

### Upload sequence

1. `VideoLabScreen._pickAndUpload` uses `FilePicker` with `withData: true` (loads entire file into RAM).
2. Optional title/stroke/distance/course/notes; stroke/course/distance inferred from filename via `VideoEventInference`.
3. `SwimmerDataNotifier.uploadVideo` → `VideoStorageService.uploadSwimVideo`:
   - Path: `{swimmer}/{uuid}{ext}` in bucket `swim-videos`
   - `uploadBinary` + `getPublicUrl`
   - Inserts row into `swim_videos` via repository
4. Snackbar: error string or `"Video uploaded."`

### Analysis sequence

1. Elite subscription gate (`SubscriptionCapabilities.canRunSwimIqAiAnalysis`).
2. `AiDataConsentDialog.ensureGranted`.
3. `SwimmerDataNotifier.analyzeVideo`:
   - Optional pose path (never runs today).
   - `GeminiSwimAnalysisService.analyzeVideo` → Edge Function.
   - On `GeminiAnalysisException`: return error message.
   - On **any other** exception: silent fallback to `AiSwimAnalysisService` (notes-only).
   - Insert into `swim_video_analyses` (or keep local `local-{videoId}` on insert failure).
4. Snackbar treats `null` return as **“AI analysis saved.”**

### Key files

| Role | Path |
|------|------|
| Upload UI | `swimiq/lib/screens/video_lab/video_lab_screen.dart` |
| Orchestration | `swimiq/lib/providers/swimmer_data_provider.dart` |
| Storage | `swimiq/lib/core/services/video_storage_service.dart` |
| Gemini client | `swimiq/lib/core/services/gemini_swim_analysis_service.dart` |
| Notes fallback | `swimiq/lib/core/services/ai_swim_analysis_service.dart` |
| Pose facade | `swimiq/lib/core/services/swim_pose_analysis_service.dart` |
| Pose stubs | `swim_pose_analysis_impl_{web,io,stub}.dart` |
| Models | `swim_video.dart`, `swim_video_analysis.dart`, `swim_pose_metrics.dart`, `video_models.dart` |
| Repository | `swimiq/lib/data/repositories/swimiq_repository.dart` |

---

## 2. Supabase buckets and database tables

### Bucket

| Bucket | Evidence | Notes |
|--------|----------|-------|
| `swim-videos` | `VideoStorageService.bucketName`, Edge Function `BUCKET` | **Not created by SQL migration** — comment in `001_video_standards.sql` says create in Dashboard. Public URLs used for playback. Also used for profile photos (`profile_photo_service.dart`). |

### Tables (video-related)

From `swimiq/supabase/migrations/001_video_standards.sql`:

**`public.swim_videos`**

- `id uuid PK`
- `swimmer`, `swimmer_name`
- `title`, `stroke`, `distance` (text), `course`
- `storage_path`, `video_url`, `notes`
- `created_at`

**`public.swim_video_analyses`**

- `id uuid PK`
- `swim_video_id` FK → `swim_videos`
- `swimmer`, `swimmer_name`
- `summary`, `strengths`, `improvements`
- `technique_score`, `pace_score`, `overall_score`
- `analysis_json jsonb`
- `created_at`

**Missing for new engine (to be proposed in rebuild plan):**

- Job queue / status machine
- Events, per-metric rows, artifacts, reports, feedback, model versions
- User ownership columns / athlete ownership with RLS

### RLS (critical)

Both `swim_videos` and `swim_video_analyses` use:

```sql
FOR ALL USING (true) WITH CHECK (true);
```

Any client with the anon key can read/write all rows. `usa_time_standards` was later tightened in `003_usa_standards_readonly.sql`; video tables were not.

---

## 3. Current Gemini calls

### Only production Gemini integration

| Item | Detail |
|------|--------|
| Location | `swimiq/supabase/functions/analyze-swim-video/index.ts` |
| Model | `gemini-2.0-flash` |
| Transport | Full video downloaded via service role → base64 `inline_data` → `generateContent` |
| Max size | `MAX_VIDEO_BYTES = 18 * 1024 * 1024` |
| Output | Structured coaching narrative + integer scores (technique/pace/overall) |
| Auth | JWT required (`config.toml` `verify_jwt = true` + `getUser()`) |
| Ownership check | **None** — any authenticated user can pass any `storage_path` |

### Flutter client

`GeminiSwimAnalysisService` invokes `analyze-swim-video` with:

- `video_id`, `storage_path`, event fields, `coach_context`, optional `pose_metrics`

Does **not** check HTTP status the way Stripe checkout does; relies on `data['error']` in body. Default score when parse fails: **70**.

### Prompt behavior (architectural conflict)

The Edge Function prompt asks Gemini to:

- Watch the attached video
- Be specific about body line, kick, pull, breathing, turns, underwater, finish
- Produce scores and coaching priorities

This is Gemini-as-measurement-engine. The rebuild forbids Gemini for frame-precise measurements (stroke counts, angles, timestamps, tempo, breakouts, underwater kicks, turn durations).

No client-side `google_generative_ai` package exists in `pubspec.yaml` (good for secret hygiene).

---

## 4. Current MediaPipe / pose calls

| File | Behavior |
|------|----------|
| `swim_pose_analysis_impl_web.dart` | `isPoseAnalysisSupported => false`; returns `null` |
| `swim_pose_analysis_impl_io.dart` | Same |
| `swim_pose_analysis_impl_stub.dart` | Same |
| `swim_pose_metrics_calculator.dart` | Pure Dart angle/cycle helpers — **orphaned** |
| `swim_pose_metrics.dart` | Model still wired into Gemini request body when pose exists |

**No** `pose_detection`, `mediapipe`, or similar dependency in `pubspec.yaml`.

Docs (`POSE_AND_GEMINI.md`, Flutter README feature table) still describe MediaPipe/BlazePose as present or “coming back.” That documentation is **obsolete relative to this tree**.

MediaPipe may remain later only as an optional fallback adapter for diagnostics — **not** the production foundation.

---

## 5. Backend / edge-function calls

| Function | Video analysis? | Notes |
|----------|-----------------|-------|
| `analyze-swim-video` | **Yes** | Sole analysis backend today |
| `create-stripe-checkout` | Indirect | Gates Elite AI |
| `stripe-webhook` | Indirect | Subscription state |

There is **no** Python FastAPI analysis service in the repo today.

Root Python:

| Path | Role |
|------|------|
| `app.py` | Streamlit tracker (reference); Video Lab is a nav label only |
| `swimiq_version2_complete_app.py` | Streamlit complete app; not Flutter video pipeline |
| `requirements.txt` | `streamlit`, `plotly`, `pandas`, `supabase` — no CV stack |

---

## 6. Environment variables

### Flutter / shared client

| Variable | Source |
|----------|--------|
| `SUPABASE_URL` | `.env.example`, `swimiq/.env.example`, `Env` / dart-define |
| `SUPABASE_ANON_KEY` | Same |

### Edge Function secrets (documented)

| Variable | Purpose |
|----------|---------|
| `GEMINI_API_KEY` | Gemini generateContent |
| `SUPABASE_URL` | Clients |
| `SUPABASE_ANON_KEY` | User JWT validation |
| `SUPABASE_SERVICE_ROLE_KEY` | Storage download |
| Stripe secrets | Billing (separate) |

### Streamlit

| Variable | Source |
|----------|--------|
| `SUPABASE_URL`, `SUPABASE_KEY` | `.streamlit/secrets.toml.example` |

**Good:** Gemini key is not embedded in Flutter.  
**Risk:** Service role used without path ownership validation; open RLS makes anon key extremely powerful for video rows.

---

## 7. Duplicated analysis logic

| Engine | Class / location | What it actually does |
|--------|------------------|------------------------|
| V2 Gemini | Edge Function + `GeminiSwimAnalysisService` | Whole-video Gemini narrative + scores |
| V1 notes | `AiSwimAnalysisService` | Regex/heuristic report from upload notes + metadata; disclaimer admits “not automatic video measurement” |
| Pose metrics | Calculator + stubs | Dead path; docs claim otherwise |

Both V1 and V2 produce similar section shapes (Quick Summary, priorities, drills), which makes silent fallback look like a successful Gemini run.

---

## 8. Obsolete / placeholder / fabricated output

| Item | Why |
|------|-----|
| Silent V1 fallback on non-`GeminiAnalysisException` | User sees success without Gemini |
| Notes-derived scores clamped ~55–88 | Fabricated technique/pace/overall scores |
| Gemini `clampScore` default **70** | Inflates missing scores |
| Pose stubs always null | “mediapipe” engines never produced |
| `POSE_AND_GEMINI.md` Chrome BlazePose claims | Incorrect for current code |
| Streamlit `app.py` / version2 app | Not the Flutter analysis pipeline |
| Orphaned `SwimPoseMetricsCalculator` | No frame sampler feeds it |

---

## 9. Security problems

1. **Open RLS** on `swim_videos` and `swim_video_analyses` (`USING (true)`).
2. **Public bucket / public URLs** for swim videos (and shared with profile photos).
3. **Edge Function** downloads any `storage_path` with service role; no check that the path belongs to the caller or to a `swim_videos` row they own.
4. **CORS `*`** on analysis function (acceptable for web clients, loose with open RLS).
5. Hardcoded project URL appears in tests (`bryurwyeosbffvfpdpbv.supabase.co`) — hygiene issue, not a live secret leak by itself.
6. Client correctly avoids Gemini and service-role keys.

---

## 10. Incompatible / missing dependency versions

### Flutter (`swimiq/pubspec.yaml`)

| Package | Declared | Analysis relevance |
|---------|----------|--------------------|
| `supabase_flutter` | ^2.9.0 | Upload + function invoke |
| `file_picker` | ^8.3.7 | Upload |
| `video_player` | ^2.10.0 | Playback |
| MediaPipe / pose_detection | **absent** | Pose path impossible |
| google_generative_ai | **absent** | Correct for client |

### Python root (`requirements.txt`)

No FastAPI, OpenCV, FFmpeg bindings, PyTorch, MMPose, RTMPose, ONNX Runtime, SciPy, Google Gen AI SDK.

**Conclusion:** The target stack does not exist in-repo. A new `services/video_analysis/` environment is required; root Streamlit deps must not be mixed into the CV service.

---

## 11. Blocking synchronous work

| Location | Issue |
|----------|-------|
| `video_lab_screen.dart` `withData: true` | Entire video loaded into mobile/web memory before upload |
| Edge Function | Full download + base64 encode + single Gemini request in one HTTP invoke |
| Flutter `analyzeVideo` | Awaits full Edge Function completion (no job polling) |
| Hypothetical pose path | Would download video again before Gemini |

This blocks UX for longer clips and couples mobile wait time to Gemini latency/timeouts.

---

## 12. Places where errors are swallowed

| Location | Behavior |
|----------|----------|
| `swimmer_data_provider.dart` pose `catch (_)` | Pose failure ignored |
| Gemini `catch (_)` → V1 notes | **Silent engine swap** |
| Insert analysis `catch (_)` | Local-only analysis; still success |
| Refresh `catch (_)` after upload/analyze | Ignored |
| Load path empty `catch (_)` for videos/analyses | Fetch errors hidden |
| Gemini score defaults | Missing → 70 |

Non-negotiable rebuild rule violated today: *“Never return a generic successful coaching report when computer vision failed.”* and *“Do not silently catch exceptions.”*

---

## 13. Why the current pipeline fails (root causes)

1. **Wrong architecture:** Gemini watches the whole video and invents coaching + scores without deterministic pose/events/metrics.
2. **Pose layer removed but product still implies body mechanics.**
3. **Silent notes fallback** masks undeployed functions, auth failures (sometimes), timeouts, oversized videos, and parse issues as “AI analysis saved.”
4. **18 MB inline limit** is incompatible with typical phone race footage.
5. **No job states, no retry-from-stage, no evidence frames, no confidence contract.**
6. **No validation/preprocessing** (rotation, codec, fps, corrupt streams) before analysis.
7. **Security/RLS gaps** make data integrity and multi-tenant isolation unreliable.
8. **No golden labeled swimming dataset** — even a future RTMPose stack cannot claim accuracy without Phase 16-style evaluation.

---

## 14. File inventory (video analysis surface)

### Retain for app shell (do not rewrite)

- Auth, subscriptions, dashboard, training log, goals, meets, passport, settings
- `VideoStorageService` upload primitives (adapt later for job API)
- `swim_videos` rows as upload registry (extend schema carefully)
- Consent dialog + Elite gating concepts

### Replace / retire as analysis engine

- `supabase/functions/analyze-swim-video/**` (Gemini-as-measurer)
- Silent V1 fallback success path in `analyzeVideo`
- Pose stubs as production foundation (optional later as diagnostic adapter only)
- Docs that claim MediaPipe is live

### Obsolete / deprecate candidates

- Large portions of `swimiq/docs/POSE_AND_GEMINI.md`
- README “Video Lab + Gemini AI video analysis — Done” as accuracy claim
- Streamlit Video Lab nav (not Flutter pipeline)
- Orphaned pose calculator until a new adapter consumes landmarks (or delete after migration)

---

## 15. Audit constraints honored

- No application code modified during this audit.
- No library swaps performed.
- Findings are based on repository inspection of Flutter, Supabase migrations/functions, docs, and Python roots.

**Next document:** `docs/video_engine_rebuild_plan.md` (architecture, API schemas, directory tree, dependency matrix, migration risks, Milestone 1 tasks).

**Implementation gate:** Do not implement Milestone 1 until explicitly instructed.
