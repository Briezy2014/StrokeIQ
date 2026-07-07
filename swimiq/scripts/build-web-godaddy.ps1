# Build SwimIQ for web → upload to GoDaddy public_html
# Run from S:\swimiq after .env has SUPABASE_URL and SUPABASE_ANON_KEY

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Test-Path ".env")) {
    Write-Host "ERROR: Missing .env file. Copy .env.example to .env and add Supabase keys."
    exit 1
}

$url = $null
$key = $null
Get-Content ".env" | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim() }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim() }
}

if (-not $url -or -not $key) {
    Write-Host "ERROR: .env must contain SUPABASE_URL and SUPABASE_ANON_KEY"
    exit 1
}

Write-Host "Building SwimIQ for web (release)..."
Write-Host "Output will be in: build\web\"
Write-Host ""

flutter pub get
flutter build web --release `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DONE. Next steps:" -ForegroundColor Green
Write-Host "1. Open folder: build\web\" -ForegroundColor Green
Write-Host "2. Upload ALL files inside to GoDaddy public_html" -ForegroundColor Green
Write-Host "3. Visit https://swimiqapp.com" -ForegroundColor Green
Write-Host "See docs/WALKTHROUGH_SWIMIQAPP_COM.md" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
