#!/usr/bin/env bash
# Build SwimIQ IPA for TestFlight (run on macOS with Flutter + Xcode).
#
# Usage:
#   export SUPABASE_URL=https://xxxx.supabase.co
#   export SUPABASE_ANON_KEY=eyJ...
#   ./scripts/build-ios-testflight.sh
#
# Or edit the defaults below (do not commit real keys).

set -euo pipefail
cd "$(dirname "$0")/.."

SUPABASE_URL="${SUPABASE_URL:-https://YOUR_PROJECT.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-YOUR_ANON_KEY}"

if [[ "$SUPABASE_URL" == *YOUR_PROJECT* ]] || [[ "$SUPABASE_ANON_KEY" == YOUR_ANON_KEY ]]; then
  echo "Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables first."
  exit 1
fi

flutter pub get
flutter build ipa \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo ""
echo "Done. IPA: build/ios/ipa/*.ipa"
echo "Upload with Transporter (Mac) or Xcode Organizer."
