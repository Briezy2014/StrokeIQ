# Tests Supabase email/password login using swimiq\.env (same keys as LAUNCH-CHROME).
param(
    [string]$Email = 'owner@swimiqapp.com',
    [string]$Password = 'SwimIQ-Owner-2026'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root '.env'

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Test Supabase Login' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path -LiteralPath $envFile)) {
    Write-Host 'ERROR: Missing .env in swimiq folder' -ForegroundColor Red
    exit 1
}

$url = $null
$key = $null
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim() }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim() }
}
$url = $url -replace 'https:https//', 'https://' -replace 'https//', 'https://'
if ($url -and $url -notmatch '^https://') { $url = "https://$url" }

if (-not $url -or -not $key -or $url -match 'your-project') {
    Write-Host 'ERROR: .env needs real SUPABASE_URL and SUPABASE_ANON_KEY' -ForegroundColor Red
    exit 1
}

Write-Host "Supabase project: $url" -ForegroundColor White
Write-Host "Testing email:    $Email" -ForegroundColor White
Write-Host ''

$tokenUrl = "$url/auth/v1/token?grant_type=password"
$body = @{
    email = $Email
    password = $Password
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Headers @{
        apikey = $key
        Authorization = "Bearer $key"
        'Content-Type' = 'application/json'
    } -Body $body

    Write-Host 'SUCCESS - login works for this Supabase project!' -ForegroundColor Green
    if ($response.user.email) {
        Write-Host "  User id: $($response.user.id)" -ForegroundColor Green
        Write-Host "  Email:   $($response.user.email)" -ForegroundColor Green
    }
    Write-Host ''
    Write-Host 'If the app still fails, hard-refresh Chrome (Ctrl+F5) or run LAUNCH-CHROME.bat again.' -ForegroundColor Yellow
    exit 0
} catch {
    $detail = $_.ErrorDetails.Message
    if (-not $detail) { $detail = $_.Exception.Message }
    Write-Host 'FAILED - Supabase rejected this email/password.' -ForegroundColor Red
    Write-Host "  $detail" -ForegroundColor Red
    Write-Host ''
    Write-Host 'Fix (do this in supabase.com/dashboard):' -ForegroundColor Yellow
    Write-Host '  1. Open the project that matches the URL above' -ForegroundColor White
    Write-Host '  2. Authentication -> Users -> Add user' -ForegroundColor White
    Write-Host "     Email:    $Email" -ForegroundColor White
    Write-Host "     Password: $Password" -ForegroundColor White
    Write-Host '     Auto Confirm User: ON' -ForegroundColor White
    Write-Host '  3. SQL Editor -> run supabase/seed_owner_master.sql' -ForegroundColor White
    Write-Host '  4. Run this test again until you see SUCCESS' -ForegroundColor White
    Write-Host ''
    Write-Host 'If the user already exists: Users -> ... -> Reset password' -ForegroundColor Yellow
    exit 1
}
