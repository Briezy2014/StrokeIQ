# SwimIQ Chrome launcher — all-in-one (Kara Williams / paths with spaces)
$ErrorActionPreference = 'Stop'

$swimiqRoot = $PSScriptRoot
$strokeRoot = Split-Path -Parent $swimiqRoot

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Launch Chrome' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host "SwimIQ folder: $swimiqRoot"
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
    Write-Host 'ERROR: Flutter not found. Install to C:\flutter' -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

# --- Map F: and S: (fixes C:\Users\Kara error) ---
subst F: /D 2>$null | Out-Null
subst S: /D 2>$null | Out-Null
subst F: $flutterRoot | Out-Null
subst S: $strokeRoot | Out-Null

$flutterBat = 'F:\bin\flutter.bat'
$workDir = 'S:\swimiq'
$pubCache = 'S:\pub-cache'

New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
$env:PUB_CACHE = $pubCache
[Environment]::SetEnvironmentVariable('PUB_CACHE', $pubCache, 'User')
$env:Path = 'F:\bin;' + $env:Path

if (-not (Test-Path $flutterBat)) {
    Write-Host 'ERROR: F:\bin\flutter.bat not found after mapping.' -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}
if (-not (Test-Path $workDir)) {
    Write-Host 'ERROR: S:\swimiq not found after mapping.' -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

Set-Location $workDir
Write-Host 'OK  Flutter: F:\bin' -ForegroundColor Green
Write-Host 'OK  Project: S:\swimiq' -ForegroundColor Green
Write-Host "OK  PUB_CACHE: $pubCache" -ForegroundColor Green
Write-Host ''

# --- .env in swimiq folder ---
$envFile = Join-Path $workDir '.env'
$exampleFile = Join-Path $workDir '.env.example'

if (-not (Test-Path $envFile)) {
    if (Test-Path $exampleFile) {
        Copy-Item $exampleFile $envFile
    }
    Write-Host 'Created .env — add Supabase URL + anon key, save, run LAUNCH-CHROME.bat again.' -ForegroundColor Yellow
    notepad $envFile
    Read-Host 'Press Enter to close'
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
    Write-Host 'ERROR: Edit S:\swimiq\.env with real Supabase keys.' -ForegroundColor Red
    notepad $envFile
    Read-Host 'Press Enter to close'
    exit 1
}

Write-Host 'OK  Supabase keys loaded' -ForegroundColor Green
Write-Host 'Starting Chrome — wait 1-2 minutes...' -ForegroundColor Cyan
Write-Host ''

& $flutterBat pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "flutter pub get failed (code $LASTEXITCODE)" -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit $LASTEXITCODE
}

& $flutterBat run -d chrome `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key

$code = $LASTEXITCODE
Write-Host ''
if ($code -ne 0) {
    Write-Host "Launch failed (code $code)" -ForegroundColor Red
} else {
    Write-Host 'Chrome session ended.' -ForegroundColor Green
}
Read-Host 'Press Enter to close'
exit $code
