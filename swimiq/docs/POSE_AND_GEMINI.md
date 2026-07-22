# Video analysis: Elote metrics + Gemini plan (not Gemini-as-measurer)

## The rule (read this)

| Layer | Who does it | Role |
|-------|-------------|------|
| **Pose / metrics** | **Elote** (`services/video_analysis`) — RTMDet + RTMPose | Measure what happened in the video |
| **Coaching plan** | **Gemini** | Turn validated metrics into a parent-friendly plan of action |

**Gemini must not be the only thing watching the video to invent stroke counts and angles.**  
That old Edge Function path caused most “Analyze” failures and fake-looking reports.

## Product limit

Elite Video Lab accepts race clips of **2 minutes or less** (`max_duration_ms = 120000`).

## How Analyze works when V2 is on

1. Upload clip in **Elite Video Lab**
2. Tap **Analyze** → Video Engine V2 job (Elote)
3. Elote validates, tracks, poses, computes metrics
4. Gemini writes coaching narrative **from metrics JSON only**
5. Results screen shows metrics + plan

Setup: **[VIDEO_ENGINE_V2_MORNING_LAUNCH.md](VIDEO_ENGINE_V2_MORNING_LAUNCH.md)**  
Pull/merge: **[PULL_AND_MERGE.md](PULL_AND_MERGE.md)**

## `.env` flags

```
VIDEO_ENGINE_V2=true
ANALYSIS_API_BASE_URL=https://your-elote-host
VIDEO_ENGINE_V2_DUAL_RUN=false
```

## Legacy Edge Function (rollback only)

`analyze-swim-video` still exists and now uses the Gemini **File API** (higher MB limit) so short phone clips are less likely to 413. Use only if V2 is down (`VIDEO_ENGINE_V2_DUAL_RUN=true` or V2 off).

## Tips for good clips

- Side-on or 45° camera  
- Full body in frame when possible  
- **≤ 2 minutes**  
- Decent lighting  

Metrics are estimates for coaching — not official meet timing.
