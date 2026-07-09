param(
    [string]$SupabaseUrl,
    [string]$SupabaseAnonKey
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

# Pub cache MUST be on same drive as project (S:) — C:\SwimIQPub + S:\swimiq breaks Kotlin
$pubCache = "S:\pub-cache"
New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
$env:PUB_CACHE = $pubCache
[Environment]::SetEnvironmentVariable("PUB_CACHE", $pubCache, "Process")
Write-Host "PUB_CACHE=$pubCache (same drive as project)" -ForegroundColor Cyan

& (Join-Path $PSScriptRoot "fix-android-gradle.ps1")

$keyProps = Join-Path $repoRoot "android\key.properties"
if (-not (Test-Path $keyProps)) {
    Write-Host ""
    Write-Host "WARNING: android\key.properties not found." -ForegroundColor Yellow
    Write-Host "Release will be signed with DEBUG keys (Play upload will fail)." -ForegroundColor Yellow
    Write-Host "Copy android\key.properties.example and create your upload keystore first." -ForegroundColor Yellow
    Write-Host "See docs\ANDROID_RELEASE.md" -ForegroundColor Yellow
    Write-Host ""
}

$envFile = Join-Path $repoRoot ".env"
if (-not $SupabaseUrl -and (Test-Path $envFile)) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*SUPABASE_URL=(.+)$') { $SupabaseUrl = $Matches[1].Trim() }
        if ($_ -match '^\s*SUPABASE_ANON_KEY=(.+)$') { $SupabaseAnonKey = $Matches[1].Trim() }
    }
}

if (-not $SupabaseUrl -or -not $SupabaseAnonKey) {
    throw "SUPABASE_URL and SUPABASE_ANON_KEY are required. Pass -SupabaseUrl / -SupabaseAnonKey or set them in .env"
}

Write-Host "Cleaning old build cache..." -ForegroundColor Yellow
$buildDir = Join-Path $repoRoot "build"
if (Test-Path $buildDir) {
    Remove-Item -LiteralPath $buildDir -Recurse -Force -ErrorAction SilentlyContinue
}

$gradlew = Join-Path $repoRoot "android\gradlew.bat"
if (Test-Path $gradlew) {
    Push-Location (Join-Path $repoRoot "android")
    try { & .\gradlew.bat --stop 2>$null } catch { }
    Pop-Location
}

Write-Host "Building SwimIQ Android App Bundle (release)..." -ForegroundColor Cyan
flutter clean
flutter pub get
flutter build appbundle --release `
    "--dart-define=SUPABASE_URL=$SupabaseUrl" `
    "--dart-define=SUPABASE_ANON_KEY=$SupabaseAnonKey"

$aab = Join-Path $repoRoot "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $aab) {
    Write-Host ""
    Write-Host "Done: $aab" -ForegroundColor Green
} else {
    throw "Build finished but app-release.aab was not found."
}
