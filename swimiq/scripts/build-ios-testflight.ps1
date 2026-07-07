# SwimIQ TestFlight build helper (Windows — prepares commands; IPA requires macOS or Codemagic).
#
# Usage on Windows (after pulling to S:\swimiq):
#   $env:SUPABASE_URL = "https://xxxx.supabase.co"
#   $env:SUPABASE_ANON_KEY = "eyJ..."
#   .\scripts\build-ios-testflight.ps1
#
# This script validates keys and prints the exact Mac command to run.

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$url = $env:SUPABASE_URL
$key = $env:SUPABASE_ANON_KEY

if (-not $url -or -not $key) {
    Write-Host @"

SwimIQ TestFlight — set Supabase keys first:

  `$env:SUPABASE_URL = "https://YOUR_PROJECT.supabase.co"
  `$env:SUPABASE_ANON_KEY = "your-anon-key"

Then run this script again.

For full steps see docs/TESTFLIGHT.md

"@
    exit 1
}

Write-Host "Keys OK. On a Mac, run:" -ForegroundColor Green
Write-Host ""
Write-Host @"
cd swimiq
flutter pub get
flutter build ipa `
  --dart-define=SUPABASE_URL=$url `
  --dart-define=SUPABASE_ANON_KEY=$key
"@
Write-Host ""
Write-Host "Then upload build/ios/ipa/*.ipa with Transporter or Xcode."
Write-Host "Invite testers in App Store Connect -> TestFlight."
Write-Host "Guide: docs/TESTFLIGHT.md"
