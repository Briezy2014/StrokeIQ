# Elote Video Lab — Analysis Service

Isolated Python FastAPI backend for SwimIQ video analysis.

**Current milestone: Milestone 9**

| Milestone | Scope |
|-----------|--------|
| 1 | Validation, metadata, jobs, logging, `/health` |
| 2 | RTMDet detection, tracking, target selection, diagnostics |
| 3 | RTMPose WholeBody pose (MMPose), stages A/B/C |
| 4 | Pose validation, temporal smoothing, quality flags, skeleton overlay |
| 5 | Butterfly surface-stroke cycles + reliable timing/breathing metrics |
| 6 | Underwater phase, dolphin kicks, breakout |
| 7 | Turn / finish event framework + wall calibration |
| 8 | Confidence-aware Gemini coaching reports (structured CV results only) |
| 9 | Flutter + Supabase integration (`video_engine_v2` feature flag) |

**Not in Milestone 9:** Removing the legacy Edge Function engine (kept as `video_engine_legacy` until V2 real-video approval).

## Pose stages (no auto-advance)

```bash
python scripts/download_rtmpose.py
python scripts/make_pose_clips.py
python scripts/run_pose_stage.py --stage A --source tests/fixtures/pose_stage_a_still.jpg
python scripts/run_pose_stage.py --stage B --source tests/fixtures/pose_stage_b_5s.mp4
python scripts/run_pose_stage.py --stage C --source tests/fixtures/pose_stage_c_full.mp4
```

Stage B requires Stage A acceptance; Stage C requires Stage B acceptance.

## Setup (CPU)

See [`docs/POSE_DEPENDENCIES.md`](docs/POSE_DEPENDENCIES.md) for the pinned matrix.

```bash
cd services/video_analysis
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pip install torch==2.2.2 torchvision==0.17.2 --index-url https://download.pytorch.org/whl/cpu
pip install numpy==1.26.4 scipy==1.11.4 opencv-python==4.10.0.84
pip install mmengine==0.10.7
pip install mmcv==2.2.0 -f https://download.openmmlab.com/mmcv/dist/cpu/torch2.2.0/index.html
pip install mmdet==3.3.0 mmpose==1.3.2
python scripts/patch_mmdet_mmcv.py
python scripts/download_rtmdet.py
python scripts/download_rtmpose.py
```

## Butterfly surface analysis (Milestone 5)

Uses Milestone 4 `smoothed_pose.json` only (raw poses are never mutated).

```bash
python scripts/make_butterfly_fixtures.py
pytest tests/unit/test_butterfly_analyzer.py -q
```

Enable in a job via `options.run_butterfly_analysis=true` with `event.stroke=butterfly`.

## Underwater / breakout (Milestone 6)

```bash
python scripts/make_underwater_fixtures.py
pytest tests/unit/test_underwater_analyzer.py -q
```

Enable via `options.run_underwater_analysis=true` (uses M4 smoothed poses; optional M5 surface entry frames).

## Turn / finish framework (Milestone 7)

```bash
python scripts/make_turn_finish_fixtures.py
pytest tests/unit/test_turn_finish_analyzers.py -q
```

Enable via `options.run_turn_analysis` / `options.run_finish_analysis`. Unsupported views return explicit `unavailable` events/metrics.

## Gemini coaching report (Milestone 8)

Uses the official `google-genai` SDK. The API key is read only from backend env (`GEMINI_API_KEY`). Gemini receives structured metrics/events/confidence/limitations — never raw video.

```bash
pytest tests/unit/test_gemini_report.py -q
```

Enable via `options.generate_gemini_report=true`. If Gemini fails, deterministic metrics are still returned.

## Flutter / Supabase integration (Milestone 9)

Backend validates Supabase JWTs (`SUPABASE_AUTH_REQUIRED=true` in production), downloads private `swim-videos` objects with the **service role** (never in Flutter), and optionally persists jobs/metrics/reports to Supabase tables with RLS.

```bash
pytest tests/integration/test_flutter_bridge_api.py -q
cd ../../swimiq && flutter test test/video_engine_v2_test.dart
```

Flutter enablement (test accounts first):

```
VIDEO_ENGINE_V2=true
VIDEO_ENGINE_V2_ALLOWLIST=tester@example.com
ANALYSIS_API_BASE_URL=https://your-analysis-host
```

Legacy Video Lab (`analyze-swim-video` Edge Function) remains available when V2 is disabled.

## Test

```bash
pytest -q
```

## MediaPipe

Disabled as a production dependency. Not used by the pose pipeline.
