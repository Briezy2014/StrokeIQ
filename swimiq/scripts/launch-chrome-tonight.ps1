# SwimIQ — one-click Chrome launcher for Windows (paths with spaces + Supabase)
# Run: double-click LAUNCH-CHROME.bat in the swimiq folder

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$strokeRoot = Split-Path -Parent $projectRoot

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ — Chrome preview (tonight mode)' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

# --- Flutter (map F: if path has spaces) ---
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
    $cmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($cmd) { $flutterBin = Split-Path -Parent $cmd.Source }
}
if (-not $flutterBin) {
    Write-Host 'ERROR: Flutter not found. Install to C:\flutter' -ForegroundColor Red
    exit 1
}

$flutterRoot = $flutterBin.TrimEnd('\bin')
if ($flutterRoot -match ' ') {
    subst F: $flutterRoot 2>$null
    $flutterBin = 'F:\bin'
    Write-Host 'OK  Flutter mapped to F:\' -ForegroundColor Green
}

# --- Project (map S: if path has spaces) ---
if ($projectRoot -match ' ' -or $strokeRoot -match ' ') {
    subst S: $strokeRoot 2>$null
    $projectRoot = 'S:\swimiq'
    Write-Host 'OK  Project mapped to S:\swimiq' -ForegroundColor Green
}

# --- Pub cache (fixes Kara Williams / objective_c error) ---
$pubCache = 'S:\pub-cache'
New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
$env:PUB_CACHE = $pubCache
$env:Path = "$flutterBin;$env:Path"
Set-Location $projectRoot

Write-Host "OK  Folder: $projectRoot" -ForegroundColor Green
Write-Host "OK  PUB_CACHE: $pubCache" -ForegroundColor Green
Write-Host ''

# --- .env must live in swimiq folder ---
$envFile = Join-Path $projectRoot '.env'
$exampleFile = Join-Path $projectRoot '.env.example'

if (-not (Test-Path $envFile)) {
    if (Test-Path $exampleFile) {
        Copy-Item $exampleFile $envFile
        Write-Host 'Created swimiq\.env — paste your Supabase keys, save, then run LAUNCH-CHROME.bat again.' -ForegroundColor Yellow
        Write-Host '  Supabase → Project Settings → API → Project URL + anon public key' -ForegroundColor Yellow
        notepad $envFile
        exit 1
    }
    Write-Host 'ERROR: Missing swimiq\.env — copy .env.example to .env' -ForegroundColor Red
    exit 1
}

$url = $null
$key = $null
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim() }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim() }
}

# Fix common URL typos
if ($url) {
    $url = $url -replace 'https:https//', 'https://'
    $url = $url -replace 'https//', 'https://'
    if ($url -notmatch '^https://') { $url = "https://$url" }
}

if (-not $url -or -not $key -or $url -match 'your-project' -or $key -match 'your-supabase') {
    Write-Host 'ERROR: Edit swimiq\.env with real Supabase URL and anon key (not placeholders).' -ForegroundColor Red
    notepad $envFile
    exit 1
}

Write-Host 'OK  Supabase keys found in .env' -ForegroundColor Green
Write-Host ''
Write-Host 'Starting Chrome — first launch can take 1-2 minutes...' -ForegroundColor Cyan
Write-Host ''

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter run -d chrome `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key

exit $LASTEXITCODE
