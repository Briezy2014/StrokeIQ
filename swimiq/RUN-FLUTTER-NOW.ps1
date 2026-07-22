# Run SwimIQ Chrome while Elite is ALREADY up.
# No new API key. Does not restart Elite.
# Usage: right-click → Run with PowerShell, or:
#   powershell -ExecutionPolicy Bypass -File .\RUN-FLUTTER-NOW.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '============================================'
Write-Host '  SwimIQ - Run Flutter (Elite already up)'
Write-Host '============================================'
Write-Host ''
Write-Host 'Leave the Elite Video Lab window OPEN.'
Write-Host 'Chrome must open at 127.0.0.1 (not swimiqapp.com).'
Write-Host ''

function Test-SwimIqFolder {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
  if ($Path -ieq 'C:\FlutterWork') { return $false }
  if ($Path -match '[\\/]FlutterWork$') { return $false }
  return (Test-Path -LiteralPath (Join-Path $Path 'pubspec.yaml'))
}

$candidates = @(
  'S:\swimiq'
  'C:\SwimIQWork'
  'C:\SwimIQWork\swimiq'
  (Join-Path $PSScriptRoot '.')
  (Join-Path $PSScriptRoot 'swimiq')
  (Join-Path $env:USERPROFILE 'Desktop\StrokeIQ\swimiq')
  (Join-Path $env:USERPROFILE 'Desktop\StrokeIQ\StrokeIQ\swimiq')
  (Join-Path $env:USERPROFILE 'OneDrive\Desktop\StrokeIQ\swimiq')
  (Join-Path $env:USERPROFILE 'OneDrive\Desktop\StrokeIQ\StrokeIQ\swimiq')
)

$appDir = $null
foreach ($c in $candidates) {
  try {
    $full = [IO.Path]::GetFullPath($c)
  } catch {
    continue
  }
  if (Test-SwimIqFolder $full) {
    $appDir = $full
    break
  }
}

if (-not $appDir) {
  Write-Host 'ERROR: Could not find SwimIQ (pubspec.yaml).' -ForegroundColor Red
  Write-Host 'C:\FlutterWork is the Flutter SDK — that is NOT the app.'
  Write-Host ''
  Write-Host 'In File Explorer search This PC for: pubspec.yaml'
  Write-Host 'Open the folder that contains it, then run this script from there.'
  Read-Host 'Press Enter to close'
  exit 1
}

Write-Host "OK  App folder: $appDir" -ForegroundColor Green

# Quick Elite check (non-fatal — she may still want to launch)
try {
  $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8080/health' -TimeoutSec 3
  if ($r.StatusCode -eq 200 -and $r.Content -match 'engine_version') {
    Write-Host '[OK] Elite is still ready on 127.0.0.1:8080' -ForegroundColor Green
  } else {
    Write-Host '[WARN] Elite health looked odd. Keep Elite window open.' -ForegroundColor Yellow
  }
} catch {
  Write-Host '[WARN] Elite not answering on 8080. Start Elite first, then run this again.' -ForegroundColor Yellow
}

Set-Location -LiteralPath $appDir

$flutterCandidates = @(
  'C:\FlutterWork\bin\flutter.bat'
  (Join-Path $env:USERPROFILE 'Flutter\bin\flutter.bat')
  (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat')
  'C:\flutter\bin\flutter.bat'
  'C:\src\flutter\bin\flutter.bat'
)
$flutterBat = $null
foreach ($f in $flutterCandidates) {
  if (Test-Path -LiteralPath $f) { $flutterBat = $f; break }
}
$cmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterBat -and $cmd) { $flutterBat = $cmd.Source }

if (-not $flutterBat) {
  Write-Host 'ERROR: flutter.bat not found.' -ForegroundColor Red
  Read-Host 'Press Enter to close'
  exit 1
}

$env:Path = "$(Split-Path $flutterBat -Parent);$env:Path"
Write-Host "OK  Flutter: $flutterBat" -ForegroundColor Green
Write-Host ''

$starter = Join-Path $appDir 'start_swimiq.ps1'
if (Test-Path -LiteralPath $starter) {
  Write-Host 'Starting via start_swimiq.ps1 ...'
  powershell -NoProfile -ExecutionPolicy Bypass -File $starter
  exit $LASTEXITCODE
}

Write-Host 'start_swimiq.ps1 missing — using flutter run directly.'
if (-not (Test-Path -LiteralPath (Join-Path $appDir '.env'))) {
  Write-Host 'ERROR: No .env in app folder. Run make-env.bat first.' -ForegroundColor Red
  Read-Host 'Press Enter to close'
  exit 1
}

function Read-DotEnv {
  param([string]$Path)
  $map = @{}
  foreach ($raw in Get-Content -LiteralPath $Path) {
    $line = $raw.Trim()
    if ($line.Length -eq 0 -or $line.StartsWith('#')) { continue }
    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { continue }
    $key = $line.Substring(0, $eq).Trim()
    $val = $line.Substring($eq + 1).Trim()
    if (($val.StartsWith('"') -and $val.EndsWith('"')) -or ($val.StartsWith("'") -and $val.EndsWith("'"))) {
      $val = $val.Substring(1, $val.Length - 2)
    }
    $map[$key] = $val
  }
  return $map
}

$envMap = Read-DotEnv -Path (Join-Path $appDir '.env')
$url = [string]$envMap['SUPABASE_URL']
$key = [string]$envMap['SUPABASE_ANON_KEY']
$api = [string]$envMap['ANALYSIS_API_BASE_URL']
$v2 = [string]$envMap['VIDEO_ENGINE_V2']
if ([string]::IsNullOrWhiteSpace($api)) { $api = 'http://127.0.0.1:8080' }
$api = $api -replace 'http://localhost:', 'http://127.0.0.1:'
if ([string]::IsNullOrWhiteSpace($v2)) { $v2 = 'true' }

& $flutterBat pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$defines = @(
  "--dart-define=SUPABASE_URL=$url"
  "--dart-define=SUPABASE_ANON_KEY=$key"
  "--dart-define=VIDEO_ENGINE_V2=$v2"
  "--dart-define=ANALYSIS_API_BASE_URL=$api"
  '--dart-define=VIDEO_ENGINE_V2_ALLOWLIST='
  '--dart-define=VIDEO_ENGINE_V2_DUAL_RUN=false'
)

& $flutterBat run -d chrome @defines
exit $LASTEXITCODE
