# Elote Video Lab — Analysis Service

Isolated Python FastAPI backend for SwimIQ video analysis.

**Current milestone: Milestone 6**

| Milestone | Scope |
|-----------|--------|
| 1 | Validation, metadata, jobs, logging, `/health` |
| 2 | RTMDet detection, tracking, target selection, diagnostics |
| 3 | RTMPose WholeBody pose (MMPose), stages A/B/C |
| 4 | Pose validation, temporal smoothing, quality flags, skeleton overlay |
| 5 | Butterfly surface-stroke cycles + reliable timing/breathing metrics |
| 6 | Underwater phase, dolphin kicks, breakout |

**Not in Milestone 6:** turns/finishes, Gemini reports, Flutter integration.

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

## Test

```bash
pytest -q
```

## MediaPipe

Disabled as a production dependency. Not used by the pose pipeline.
