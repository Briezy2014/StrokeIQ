# Build SwimIQ for public web hosting (GitHub Pages, Netlify, etc.)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$baseHref = if ($env:BASE_HREF) { $env:BASE_HREF } else { '/StrokeIQ/' }

if (-not (Test-Path ".env")) {
    Write-Host "Missing swimiq/.env — add SUPABASE_URL and SUPABASE_ANON_KEY first." -ForegroundColor Red
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
    if ($key -eq 'SUPABASE_URL' -or $key -eq 'SUPABASE_ANON_KEY') {
        $defines += "--dart-define=${key}=${value}"
    }
}

if ($defines.Count -lt 2) {
    Write-Host ".env must contain SUPABASE_URL and SUPABASE_ANON_KEY." -ForegroundColor Red
    exit 1
}

flutter pub get
flutter build web --release --base-href $baseHref @defines
Copy-Item "build\web\index.html" "build\web\404.html" -Force

Write-Host "`nBuilt: swimiq\build\web" -ForegroundColor Green
Write-Host "GitHub Pages URL: https://briezy2014.github.io$baseHref`n" -ForegroundColor Cyan
