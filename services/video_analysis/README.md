# Elote Video Lab — Analysis Service

Isolated Python FastAPI backend for SwimIQ video analysis.

**Current milestone: Milestone 2**

### Milestone 1
- Video validation (`ffprobe`), metadata artifacts, jobs, logging, `/health`

### Milestone 2
- RTMDet-n person detection via ONNX Runtime (Apache-2.0)
- Replaceable `DetectorAdapter` interface
- Persistent multi-swimmer tracking
- Target selection: `automatic` | `track_id` | `normalized_coordinate` | `bounding_box`
- Diagnostics: `detections.json`, `tracks.json`, annotated tracking video, target frames, quality summary

**Not in Milestone 2:** RTMPose pose estimation, biomechanics metrics, Gemini reports, Flutter integration.

## Requirements

- Python 3.11+ (3.12 OK for local tests)
- System `ffmpeg` / `ffprobe`
- RTMDet ONNX weights (`models/rtmdet-n-person.onnx`)

## Setup

```bash
cd services/video_analysis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python scripts/download_rtmdet.py
python scripts/make_m2_fixtures.py
```

## Run API

```bash
uvicorn app.main:app --reload --port 8080
```

## Test (reproducible)

```bash
cd services/video_analysis
source .venv/bin/activate
pytest -q
```

## Artifacts (per job)

```
analysis_artifacts/{job_id}/
  metadata.json
  detections.json
  tracks.json
  tracking_quality_summary.json
  annotated_tracking.mp4
  frames/target/
  events/tracking_events.json
```

## Next milestone

Milestone 3: RTMPose WholeBody inference (image → short clip → full clip).
