# SwimIQ — launch Flutter web in Chrome (Windows paths with spaces safe)
# Requires .env with SUPABASE_URL and SUPABASE_ANON_KEY (see .env.example)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$strokeRoot = Split-Path -Parent $projectRoot

$flutterCandidates = @(
    "$env:USERPROFILE\flutter",
    'C:\flutter',
    'C:\src\flutter'
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
    Write-Host 'ERROR: Flutter not found. Install to C:\flutter (no spaces) or see docs/WINDOWS_SETUP.md'
    exit 1
}

$flutterRoot = $flutterBin.TrimEnd('\bin')
if ($flutterRoot -match ' ') {
    subst F: $flutterRoot 2>$null
    $flutterBin = 'F:\bin'
    Write-Host 'Mapped Flutter to F:\ (path had spaces)' -ForegroundColor Yellow
}

if ($projectRoot -match ' ' -or $strokeRoot -match ' ') {
    subst S: $strokeRoot 2>$null
    $projectRoot = 'S:\swimiq'
    Write-Host 'Mapped project to S:\swimiq (path had spaces)' -ForegroundColor Yellow
}

$pubCache = 'S:\pub-cache'
New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
$env:PUB_CACHE = $pubCache
$env:Path = "$flutterBin;$env:Path"

Set-Location $projectRoot

Write-Host "`nSwimIQ Flutter web launcher" -ForegroundColor Cyan
Write-Host "Project: $projectRoot"
Write-Host "Flutter: $flutterBin"
Write-Host "PUB_CACHE: $pubCache`n"

if (-not (Test-Path '.env')) {
    if (Test-Path '.env.example') {
        Copy-Item '.env.example' '.env'
        Write-Host 'Created .env from .env.example — add your Supabase keys, then run this script again.' -ForegroundColor Yellow
        Write-Host '  Supabase → Project Settings → API → Project URL + anon public key' -ForegroundColor Yellow
        notepad .env
        exit 1
    }
    Write-Host 'ERROR: Missing .env file. Copy .env.example to .env and add Supabase keys.'
    exit 1
}

$url = $null
$key = $null
Get-Content '.env' | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim() }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim() }
}

if (-not $url -or -not $key -or $url -match 'your-project' -or $key -match 'your-supabase') {
    Write-Host 'ERROR: .env must contain real SUPABASE_URL and SUPABASE_ANON_KEY (not placeholders).' -ForegroundColor Red
    Write-Host '  Supabase → Project Settings → API' -ForegroundColor Yellow
    notepad .env
    exit 1
}

flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nIf pub get still fails, run scripts\setup-short-path.bat once," -ForegroundColor Yellow
    Write-Host "open a NEW PowerShell window, then run .\run-chrome.bat again.`n" -ForegroundColor Yellow
    exit $LASTEXITCODE
}

Write-Host 'Launching Chrome with Supabase configured...' -ForegroundColor Green
flutter run -d chrome `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key
