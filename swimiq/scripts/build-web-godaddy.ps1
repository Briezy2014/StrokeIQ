# Build SwimIQ for web → upload to GoDaddy public_html
# Run from S:\swimiq after .env has SUPABASE_URL and SUPABASE_ANON_KEY
# See docs/WINDOWS_SETUP.md if you see: 'C:\Users\Kara' is not recognized

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$strokeRoot = Split-Path -Parent $projectRoot

# Flutter + Pub cache under "Kara Williams" break native hooks — map to drive letters.
$flutterCandidates = @(
    "$env:USERPROFILE\flutter",
    "C:\flutter",
    "C:\src\flutter"
)

$flutterBin = $null
foreach ($candidate in $flutterCandidates) {
    if (Test-Path "$candidate\bin\flutter.bat") {
        $flutterBin = "$candidate\bin"
        break
    }
}

if (-not $flutterBin) {
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCmd) { $flutterBin = Split-Path -Parent $flutterCmd.Source }
}

if (-not $flutterBin) {
    Write-Host "ERROR: Flutter not found. Install to C:\flutter (no spaces) or see docs/WINDOWS_SETUP.md"
    exit 1
}

$flutterRoot = $flutterBin.TrimEnd('\bin')
if ($flutterRoot -match " ") {
    subst F: $flutterRoot 2>$null
    $flutterBin = "F:\bin"
    Write-Host "Mapped Flutter to F:\ (path had spaces)"
}

if ($projectRoot -match " ") {
    subst S: $strokeRoot 2>$null
    $projectRoot = "S:\swimiq"
    Write-Host "Mapped project to S:\swimiq (path had spaces)"
}

$pubCache = "S:\pub-cache"
New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
$env:PUB_CACHE = $pubCache
$env:Path = "$flutterBin;$env:Path"

Set-Location $projectRoot

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

flutter clean
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
