# SwimIQ — launch Flutter web in Chrome (loads Supabase keys from .env)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host "`nSwimIQ Flutter web launcher" -ForegroundColor Cyan
Write-Host "Folder: $(Get-Location)`n"

if (-not (Test-Path ".env")) {
    Write-Host "Missing .env in this folder. Copy .env.example to .env and add your keys." -ForegroundColor Red
    Write-Host "Path: $(Join-Path (Get-Location) '.env')`n" -ForegroundColor Yellow
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "Created .env from .env.example — edit it, then run this script again.`n" -ForegroundColor Yellow
    }
    exit 1
}

$defines = @()
Get-Content ".env" | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq '' -or $line.StartsWith('#')) { return }
    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { return }
    $key = $line.Substring(0, $eq).Trim()
    $value = $line.Substring($eq + 1).Trim()
    if ($value.StartsWith('"') -and $value.EndsWith('"')) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    if ($key -eq 'SUPABASE_URL' -or $key -eq 'SUPABASE_ANON_KEY') {
        $defines += "--dart-define=${key}=${value}"
    }
}

if ($defines.Count -lt 2) {
    Write-Host ".env must contain SUPABASE_URL and SUPABASE_ANON_KEY." -ForegroundColor Red
    exit 1
}

flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nIf pub get failed and your path contains spaces (e.g. Kara Williams)," -ForegroundColor Yellow
    Write-Host "run scripts\setup-short-path.bat from the swimiq folder, then use drive S:`n" -ForegroundColor Yellow
    exit $LASTEXITCODE
}

Write-Host "Starting Chrome with Supabase keys from .env ...`n" -ForegroundColor Green
flutter run -d chrome @defines
