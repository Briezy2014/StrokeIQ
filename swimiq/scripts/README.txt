# SwimIQ scripts folder
# =====================
#
# Chrome preview (Kara / Windows paths with spaces):
#   launch-chrome-tonight.ps1  — full launcher (maps F:, S:, PUB_CACHE, reads .env)
#   kara-fix-windows-once.ps1  — one-time path fix
#   setup-short-path.bat       — maps drive S: to StrokeIQ folder
#
# Deploy:
#   build-web-godaddy.ps1      — flutter build web for swimiqapp.com upload
#   build-ios-testflight.ps1   — iOS TestFlight build (Mac or CI)
#   build-ios-testflight.sh    — iOS TestFlight build (bash)
#
# Billing:
#   set-supabase-stripe-secrets.ps1 — push Stripe Price IDs to Supabase secrets
#
# From swimiq folder, double-click:
#   LAUNCH-CHROME.bat  → runs scripts\launch-chrome-tonight.ps1
#   FIX-KARA-PATHS.bat → runs scripts\kara-fix-windows-once.ps1
