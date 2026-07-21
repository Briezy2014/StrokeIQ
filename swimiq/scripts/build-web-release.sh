#!/usr/bin/env bash
# Build SwimIQ for public web hosting (GitHub Pages, Netlify, etc.)
set -euo pipefail
cd "$(dirname "$0")/.."

BASE_HREF="${BASE_HREF:-/StrokeIQ/}"

defines=()
if [[ -f .env ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -z "$line" ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    if [[ "$key" == "SUPABASE_URL" || "$key" == "SUPABASE_ANON_KEY" ]]; then
      defines+=(--dart-define="${key}=${value}")
    fi
  done < .env
fi

if [[ ${#defines[@]} -lt 2 ]]; then
  echo "Missing Supabase keys. Add SUPABASE_URL and SUPABASE_ANON_KEY to swimiq/.env"
  exit 1
fi

flutter pub get
flutter build web --release --base-href "$BASE_HREF" "${defines[@]}"
cp build/web/index.html build/web/404.html

echo ""
echo "Built: swimiq/build/web"
echo "Upload that folder to your host, or push to main to deploy via GitHub Actions."
echo "GitHub Pages URL: https://briezy2014.github.io${BASE_HREF}"
