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

$keyProps = Join-Path $repoRoot "android\key.properties"
$keystoreFile = Join-Path $repoRoot "android\keystore\swimiq-upload.jks"
if (-not (Test-Path $keyProps)) {
    Write-Host ""
    Write-Host "ERROR: android\key.properties not found." -ForegroundColor Red
    Write-Host "Run GENERATE-ANDROID-KEYSTORE.bat first." -ForegroundColor Yellow
    throw "Missing android\key.properties"
}
if (-not (Test-Path $keystoreFile)) {
    throw "Missing android\keystore\swimiq-upload.jks — run GENERATE-ANDROID-KEYSTORE.bat"
}

$envFile = Join-Path $repoRoot ".env"
if (-not $SupabaseUrl -and (Test-Path $envFile)) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*SUPABASE_URL=(.+)$') { $SupabaseUrl = $Matches[1].Trim() }
        if ($_ -match '^\s*SUPABASE_ANON_KEY=(.+)$') { $SupabaseAnonKey = $Matches[1].Trim() }
    }
}

if (-not $SupabaseUrl -or -not $SupabaseAnonKey -or
    $SupabaseUrl -match 'your-project' -or
    $SupabaseAnonKey -match 'your-supabase-anon-key') {
    throw "SUPABASE_URL and SUPABASE_ANON_KEY must be REAL values (not placeholders). Fix .env — see FIX-ENV-FOR-PLAY.txt"
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
