# SwimIQ Windows Chrome launcher.
# Reads swimiq\.env and ALWAYS passes --dart-define values to Flutter web.
# This is required because Flutter web does not reliably load .env by itself.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

function Read-DotEnv {
  param([Parameter(Mandatory = $true)][string]$Path)
  $map = @{}
  foreach ($raw in Get-Content -LiteralPath $Path) {
    $line = $raw.Trim()
    if ($line.Length -eq 0) { continue }
    if ($line.StartsWith('#')) { continue }
    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { continue }
    $key = $line.Substring(0, $eq).Trim()
    $val = $line.Substring($eq + 1).Trim()
    if (
      ($val.StartsWith('"') -and $val.EndsWith('"')) -or
      ($val.StartsWith("'") -and $val.EndsWith("'"))
    ) {
      $val = $val.Substring(1, $val.Length - 2)
    }
    $map[$key] = $val
  }
  return $map
}

Write-Host ''
Write-Host '============================================'
Write-Host '  SwimIQ Chrome launcher (PowerShell)'
Write-Host "  Folder: $PWD"
Write-Host '============================================'
Write-Host ''

if (-not (Test-Path -LiteralPath '.env')) {
  $oldEnv = Join-Path $PSScriptRoot '..\..\StrokeIQ\swimiq\.env'
  if (Test-Path -LiteralPath $oldEnv) {
    Copy-Item -LiteralPath $oldEnv -Destination '.env' -Force
    Write-Host '[OK] Copied .env from your old Desktop\StrokeIQ\swimiq folder'
  }
  else {
    Write-Host '[FAIL] No .env file in this folder.' -ForegroundColor Red
    Write-Host 'Run .\make-env.bat first, save your Supabase keys, then run again.'
    exit 1
  }
}

$envMap = Read-DotEnv -Path '.env'
$url = [string]$envMap['SUPABASE_URL']
$key = [string]$envMap['SUPABASE_ANON_KEY']
$api = [string]$envMap['ANALYSIS_API_BASE_URL']
$v2 = [string]$envMap['VIDEO_ENGINE_V2']

if ([string]::IsNullOrWhiteSpace($api)) { $api = 'http://localhost:8080' }
# Default OFF until the Python analysis server is running locally.
# Legacy Video Lab (Edge Function + consent dialog) stays fully usable.
if ([string]::IsNullOrWhiteSpace($v2)) { $v2 = 'false' }

Write-Host "SUPABASE_URL=$url"
if ([string]::IsNullOrWhiteSpace($key)) {
  Write-Host 'SUPABASE_ANON_KEY=(missing)'
}
else {
  Write-Host ("SUPABASE_ANON_KEY=(hidden, {0} chars)" -f $key.Length)
}
Write-Host "VIDEO_ENGINE_V2=$v2"
Write-Host "ANALYSIS_API_BASE_URL=$api"
Write-Host ''

if ([string]::IsNullOrWhiteSpace($url) -or $url -match 'your-project') {
  Write-Host '[FAIL] SUPABASE_URL is missing or still a placeholder.' -ForegroundColor Red
  exit 1
}
if ($url -match 'https://https') {
  Write-Host '[FAIL] SUPABASE_URL has a double https. Fix .env to one https://' -ForegroundColor Red
  exit 1
}
if ([string]::IsNullOrWhiteSpace($key) -or $key -match 'your-supabase-anon-key') {
  Write-Host '[FAIL] SUPABASE_ANON_KEY is missing or still a placeholder.' -ForegroundColor Red
  exit 1
}

Write-Host '[OK] .env looks usable'
Write-Host ''
Write-Host 'Running flutter pub get...'
flutter pub get
if ($LASTEXITCODE -ne 0) {
  Write-Host '[FAIL] flutter pub get failed' -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host ''
Write-Host '[OK] Dependencies ready.'
Write-Host 'Starting Chrome NOW with dart-defines (leave this window open)...'
Write-Host ''

$defines = @(
  "--dart-define=SUPABASE_URL=$url"
  "--dart-define=SUPABASE_ANON_KEY=$key"
  "--dart-define=VIDEO_ENGINE_V2=$v2"
  "--dart-define=ANALYSIS_API_BASE_URL=$api"
  '--dart-define=VIDEO_ENGINE_V2_ALLOWLIST='
  '--dart-define=VIDEO_ENGINE_V2_DUAL_RUN=false'
)

flutter run -d chrome @defines
$code = $LASTEXITCODE
Write-Host ''
if ($code -ne 0) {
  Write-Host "[FAIL] flutter run exited with code $code" -ForegroundColor Red
}
else {
  Write-Host '[OK] flutter run finished'
}
exit $code
