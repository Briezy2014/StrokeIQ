#!/usr/bin/env bash
# Deploy the Gemini video analysis edge function (supports clips up to ~100 MB).
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Deploying analyze-swim-video (Gemini File API for large clips)..."
supabase functions deploy analyze-swim-video
echo "Done. Re-run AI analysis on large videos in Video Lab."
