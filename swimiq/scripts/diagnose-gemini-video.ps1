# SwimIQ — find out WHY Gemini video analysis fails (writes GEMINI-DIAGNOSIS.txt)
param(
    [string]$Email = 'demo@swimiqapp.com',
    [string]$Password = 'SwimIQ'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root '.env'
$outFile = Join-Path $root 'GEMINI-DIAGNOSIS.txt'

function Write-Line($text) {
    Write-Host $text
    Add-Content -LiteralPath $outFile -Value $text
}

if (Test-Path -LiteralPath $outFile) {
    Remove-Item -LiteralPath $outFile -Force
}

Write-Line '============================================================'
Write-Line ' SWIMIQ GEMINI VIDEO DIAGNOSIS'
Write-Line " $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Line '============================================================'
Write-Line ''

try {
    if (-not (Test-Path -LiteralPath $envFile)) {
        throw "Missing swimiq\.env — run LAUNCH-CHROME.bat once so .env exists with Supabase keys."
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
        throw '.env must have real SUPABASE_URL and SUPABASE_ANON_KEY (not placeholders).'
    }

    Write-Line "Supabase URL: $url"
    Write-Line ''

    # 1) Does the function endpoint exist at all?
    Write-Line '--- TEST 1: Is analyze-swim-video deployed? ---'
    try {
        $probe = Invoke-WebRequest -Method Post -Uri "$url/functions/v1/analyze-swim-video" `
            -Headers @{ apikey = $key; 'Content-Type' = 'application/json' } `
            -Body '{}' -UseBasicParsing
        Write-Line "Unexpected: $($probe.StatusCode)"
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status -eq 401) {
            Write-Line 'OK — function EXISTS (401 without login is normal).'
        } elseif ($status -eq 404) {
            throw 'FAIL — analyze-swim-video NOT deployed. Double-click KARA-GEMINI-FIX-NOW.bat.'
        } else {
            Write-Line "Response code: $status"
        }
    }
    Write-Line ''

    # 2) Log in like the app does
    Write-Line '--- TEST 2: App login to Supabase ---'
    Write-Line "Trying email: $Email"
    $tokenUrl = "$url/auth/v1/token?grant_type=password"
    $loginBody = @{ email = $Email; password = $Password } | ConvertTo-Json
    $login = Invoke-RestMethod -Method Post -Uri $tokenUrl -Headers @{
        apikey = $key
        Authorization = "Bearer $key"
        'Content-Type' = 'application/json'
    } -Body $loginBody
    $accessToken = $login.access_token
    Write-Line 'OK — login works.'
    Write-Line ''

    # 3) Health check (needs deployed 2026-file-api version)
    Write-Line '--- TEST 3: Video server health check ---'
    $healthBody = '{"health_check":true}'
    try {
        $health = Invoke-RestMethod -Method Post -Uri "$url/functions/v1/analyze-swim-video" `
            -Headers @{
                apikey = $key
                Authorization = "Bearer $accessToken"
                'Content-Type' = 'application/json'
            } -Body $healthBody

        if ($health.ok -eq $true) {
            Write-Line "OK — Video server ready."
            Write-Line "  Version: $($health.function_version)"
            Write-Line "  Max video MB: $($health.max_video_mb)"
            Write-Line "  Gemini key on server: $($health.gemini_configured)"
            Write-Line ''
            Write-Line 'WHAT THIS MEANS:'
            Write-Line '  Server is set up. If the app still shows placeholders, tap Analyze'
            Write-Line '  on your clip AGAIN (old saved analysis is fake).'
            Write-Line '  If Analyze still fails, the error is Google Gemini rejecting the video'
            Write-Line '  (bad API key, billing, or video format) — see Test 4 in app snackbar.'
        } else {
            Write-Line "FAIL — $($health | ConvertTo-Json -Compress)"
        }
    } catch {
        $detail = $_.ErrorDetails.Message
        if (-not $detail) { $detail = $_.Exception.Message }
        Write-Line 'FAIL — health check error:'
        Write-Line $detail
        Write-Line ''
        if ($detail -match 'GEMINI_API_KEY') {
            Write-Line 'FIX: Supabase Dashboard → Project Settings → Edge Functions → Secrets'
            Write-Line '     Add secret named exactly GEMINI_API_KEY (from aistudio.google.com/apikey)'
        }
        if ($detail -match 'storage_path') {
            Write-Line 'FIX: Old server code — double-click KARA-GEMINI-FIX-NOW.bat to deploy update.'
        }
    }
    Write-Line ''

    Write-Line '--- WHAT TO DO NEXT ---'
    Write-Line '1. Double-click KARA-SEE-UPDATES-NOW.bat (get latest app)'
    Write-Line '2. Video tab → Test video server'
    Write-Line '3. Tap Analyze on your clip again (wait 90 sec)'
    Write-Line '4. If still broken, read Technical error box in the app'
    Write-Line ''
    Write-Line "Full report saved: $outFile"
    Write-Line '============================================================'

    Write-Host ''
    Write-Host "DONE — open GEMINI-DIAGNOSIS.txt in the swimiq folder" -ForegroundColor Green
    exit 0
} catch {
    Write-Line ''
    Write-Line "ERROR: $($_.Exception.Message)"
    Write-Line ''
    Write-Line 'If login failed: use the email/password you sign into SwimIQ with,'
    Write-Line 'or create demo@swimiqapp.com in Supabase (see seed_demo_master.sql).'
    Write-Line "Report saved: $outFile"
    Write-Host ''
    Write-Host "FAILED — see GEMINI-DIAGNOSIS.txt" -ForegroundColor Red
    exit 1
}
