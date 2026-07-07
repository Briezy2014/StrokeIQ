# SwimIQ — one-click Chrome launcher (forces S: and F: every launch)

$ErrorActionPreference = 'Stop'

$swimiqRoot = Split-Path -Parent $PSScriptRoot
$strokeRoot = Split-Path -Parent $swimiqRoot

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ — Chrome preview' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

# --- Find Flutter ---
$flutterRoot = $null
foreach ($candidate in @("$env:USERPROFILE\flutter", 'C:\flutter', 'C:\src\flutter')) {
    if (Test-Path "$candidate\bin\flutter.bat") {
        $flutterRoot = $candidate
        break
    }
}
if (-not $flutterRoot) {
    $cmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($cmd) { $flutterRoot = (Split-Path -Parent $cmd.Source).TrimEnd('\bin') }
}
if (-not $flutterRoot) {
    Write-Host 'ERROR: Flutter not found. Run FIX-KARA-PATHS.bat first.' -ForegroundColor Red
    exit 1
}

# --- ALWAYS map F: and S: when username or paths have spaces ---
$needsMapping = ($env:USERPROFILE -match ' ') -or ($flutterRoot -match ' ') -or ($strokeRoot -match ' ')
if ($needsMapping) {
    subst F: /D 2>$null
    subst S: /D 2>$null
    subst F: $flutterRoot
    subst S: $strokeRoot
    Write-Host 'OK  Mapped F: (Flutter) and S: (project) — no spaces' -ForegroundColor Green
}

$flutterBin = 'F:\bin'
$projectRoot = 'S:\swimiq'

if (-not (Test-Path "$flutterBin\flutter.bat")) {
    Write-Host 'ERROR: F:\bin\flutter.bat missing. Double-click FIX-KARA-PATHS.bat first.' -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $projectRoot)) {
    Write-Host 'ERROR: S:\swimiq missing. Double-click FIX-KARA-PATHS.bat first.' -ForegroundColor Red
    exit 1
}

# --- PUB_CACHE must never be under Kara Williams ---
$pubCache = 'S:\pub-cache'
New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
$env:PUB_CACHE = $pubCache
[Environment]::SetEnvironmentVariable('PUB_CACHE', $pubCache, 'User')
$env:Path = "$flutterBin;$env:Path"

Set-Location $projectRoot

Write-Host "OK  Working folder: $projectRoot" -ForegroundColor Green
Write-Host "OK  PUB_CACHE: $pubCache" -ForegroundColor Green
Write-Host ''

if ((Get-Location).Path -match ' ') {
    Write-Host 'ERROR: Still on a path with spaces. Run FIX-KARA-PATHS.bat, close VS Code, try again.' -ForegroundColor Red
    exit 1
}

# --- .env ---
$envFile = Join-Path $projectRoot '.env'
if (-not (Test-Path $envFile)) {
    Copy-Item (Join-Path $projectRoot '.env.example') $envFile
    Write-Host 'Created .env — paste Supabase keys, save, run LAUNCH-CHROME.bat again.' -ForegroundColor Yellow
    notepad $envFile
    exit 1
}

$url = $null
$key = $null
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim() }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim() }
}
if ($url) {
    $url = $url -replace 'https:https//', 'https://'
    $url = $url -replace 'https//', 'https://'
    if ($url -notmatch '^https://') { $url = "https://$url" }
}
if (-not $url -or -not $key -or $url -match 'your-project' -or $key -match 'your-supabase') {
    Write-Host 'ERROR: Put real Supabase keys in S:\swimiq\.env' -ForegroundColor Red
    notepad $envFile
    exit 1
}

Write-Host 'OK  Supabase configured' -ForegroundColor Green
Write-Host 'Starting Chrome (1-2 min first time)...' -ForegroundColor Cyan
Write-Host ''

& "$flutterBin\flutter.bat" pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$flutterBin\flutter.bat" run -d chrome `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key

exit $LASTEXITCODE
