# Elote Video Lab — Analysis Service

Isolated Python FastAPI backend for SwimIQ video analysis.

**Current milestone: Milestone 1**

- Video validation (`ffprobe`)
- Metadata extraction + artifact writing
- Analysis job creation / status / results
- Structured logging
- Configuration
- `GET /health`

**Not in Milestone 1:** RTMDet, RTMPose, Gemini reports, Flutter integration.

## Requirements

- Python 3.11+ (3.12 OK for local tests)
- System `ffmpeg` and `ffprobe` on `PATH`

## Setup

```bash
cd services/video_analysis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

## Run API

```bash
cd services/video_analysis
source .venv/bin/activate
uvicorn app.main:app --reload --port 8080
```

## Test (reproducible)

```bash
cd services/video_analysis
source .venv/bin/activate
pytest -q
```

## Milestone 1 API

| Method | Path | Notes |
|--------|------|-------|
| GET | `/health` | ffmpeg/ffprobe + engine version |
| POST | `/v1/analyses` | Body includes `video_id` + `local_path` (M1) |
| GET | `/v1/analyses/{job_id}` | Status / progress / stage |
| GET | `/v1/analyses/{job_id}/results` | Metadata only; `report` is always null |
| POST | `/v1/analyses/{job_id}/cancel` | Cancel eligible jobs |
| POST | `/v1/analyses/{job_id}/retry` | Retry failed retriable jobs |

Example:

```bash
curl -s http://127.0.0.1:8080/health | jq
curl -s -X POST http://127.0.0.1:8080/v1/analyses \
  -H 'Content-Type: application/json' \
  -d "{\"video_id\":\"demo\",\"local_path\":\"$(pwd)/tests/fixtures/valid_short.mp4\"}"
```

Artifacts land in `analysis_artifacts/{job_id}/metadata.json`.

## Docker

```bash
docker build -t elote-video-lab:m1 .
docker run --rm -p 8080:8080 elote-video-lab:m1
```

## Next milestone

Milestone 2: RTMDet swimmer detection, tracking, crops, tracking diagnostics.
