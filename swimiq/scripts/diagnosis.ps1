# SwimIQ - find out WHY Gemini video analysis fails (writes GEMINI-DIAGNOSIS.txt)
# ASCII only - works on Windows PowerShell 5.1 (Kara Williams PC)
param(
    [string]$Email = 'demo@swimiqapp.com',
    [string]$Password = 'SwimIQ'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root '.env'
$outFile = Join-Path $root 'GEMINI-DIAGNOSIS.txt'

function Write-Line {
    param([string]$Text)
    Write-Host $Text
    Add-Content -LiteralPath $outFile -Value $Text
}

if (Test-Path -LiteralPath $outFile) {
    Remove-Item -LiteralPath $outFile -Force
}

Write-Line '============================================================'
Write-Line ' SWIMIQ GEMINI VIDEO DIAGNOSIS'
Write-Line (' ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
Write-Line '============================================================'
Write-Line ''

try {
    if (-not (Test-Path -LiteralPath $envFile)) {
        throw 'Missing swimiq\.env - run KARA-CLICK-THIS.bat once so .env exists.'
    }

    $url = $null
    $key = $null
    Get-Content -LiteralPath $envFile | ForEach-Object {
        if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') {
            $url = $matches[1].Trim()
        }
        if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') {
            $key = $matches[1].Trim()
        }
    }

    $url = $url -replace 'https:https//', 'https://'
    $url = $url -replace 'https//', 'https://'
    if ($url -and $url -notmatch '^https://') {
        $url = 'https://' + $url
    }

    if (-not $url -or -not $key -or $url -match 'your-project') {
        throw '.env must have real SUPABASE_URL and SUPABASE_ANON_KEY.'
    }

    Write-Line ('Supabase URL: ' + $url)
    Write-Line ''

    Write-Line '--- TEST 1: Is analyze-swim-video deployed? ---'
    $functionUrl = $url + '/functions/v1/analyze-swim-video'
    $probeOk = $false
    try {
        Invoke-WebRequest -Method Post -Uri $functionUrl `
            -Headers @{ apikey = $key; 'Content-Type' = 'application/json' } `
            -Body '{}' -UseBasicParsing | Out-Null
        Write-Line 'Unexpected: got 200 without login'
    }
    catch {
        $resp = $_.Exception.Response
        if ($resp -and $resp.StatusCode) {
            $status = [int]$resp.StatusCode
            if ($status -eq 401) {
                Write-Line 'OK - function EXISTS (401 without login is normal).'
                $probeOk = $true
            }
            elseif ($status -eq 404) {
                throw 'FAIL - analyze-swim-video NOT deployed. Run KARA-GEMINI-FIX-NOW.bat.'
            }
            else {
                Write-Line ('Response code: ' + $status)
                $probeOk = $true
            }
        }
        else {
            throw $_.Exception.Message
        }
    }
    Write-Line ''

    Write-Line '--- TEST 2: App login to Supabase ---'
    Write-Line ('Trying email: ' + $Email)
    $tokenUrl = $url + '/auth/v1/token?grant_type=password'
    $loginBody = (@{ email = $Email; password = $Password } | ConvertTo-Json -Compress)
    $login = Invoke-RestMethod -Method Post -Uri $tokenUrl -Headers @{
        apikey          = $key
        Authorization   = ('Bearer ' + $key)
        'Content-Type'  = 'application/json'
    } -Body $loginBody

    $accessToken = $login.access_token
    if (-not $accessToken) {
        throw 'Login returned no access token.'
    }
    Write-Line 'OK - login works.'
    Write-Line ''

    Write-Line '--- TEST 3: Video server health check ---'
    $healthBody = (@{ health_check = $true } | ConvertTo-Json -Compress)
    try {
        $health = Invoke-RestMethod -Method Post -Uri $functionUrl -Headers @{
            apikey          = $key
            Authorization   = ('Bearer ' + $accessToken)
            'Content-Type'  = 'application/json'
        } -Body $healthBody

        if ($health.ok -eq $true) {
            Write-Line 'OK - Video server ready.'
            Write-Line ('  Version: ' + $health.function_version)
            Write-Line ('  Max video MB: ' + $health.max_video_mb)
            Write-Line ('  Gemini key on server: ' + $health.gemini_configured)
            Write-Line ''
            Write-Line 'WHAT THIS MEANS:'
            Write-Line '  Server is set up. If app still shows placeholders:'
            Write-Line '  Tap Analyze on your clip AGAIN (old analysis is fake).'
            Write-Line '  If Analyze still fails, Google Gemini rejected the video'
            Write-Line '  (bad API key, billing, or video format).'
        }
        else {
            Write-Line ('FAIL - ' + ($health | ConvertTo-Json -Compress))
        }
    }
    catch {
        $detail = $_.ErrorDetails.Message
        if (-not $detail) {
            $detail = $_.Exception.Message
        }
        Write-Line 'FAIL - health check error:'
        Write-Line $detail
        Write-Line ''
        if ($detail -match 'GEMINI_API_KEY') {
            Write-Line 'FIX: Supabase Dashboard - Project Settings - Edge Functions - Secrets'
            Write-Line '     Secret name: GEMINI_API_KEY (from aistudio.google.com/apikey)'
        }
        if ($detail -match 'storage_path') {
            Write-Line 'FIX: Old server code - run KARA-GEMINI-FIX-NOW.bat'
        }
    }
    Write-Line ''

    Write-Line '--- WHAT TO DO NEXT ---'
    Write-Line '1. KARA-SEE-UPDATES-NOW.bat (latest app)'
    Write-Line '2. Video tab - Test video server'
    Write-Line '3. Tap Analyze on your clip again (wait 90 sec)'
    Write-Line '4. Read Technical error box in app if still broken'
    Write-Line ''
    Write-Line ('Report saved: ' + $outFile)
    Write-Line '============================================================'

    Write-Host ''
    Write-Host 'DONE - open GEMINI-DIAGNOSIS.txt' -ForegroundColor Green
    exit 0
}
catch {
    Write-Line ''
    Write-Line ('ERROR: ' + $_.Exception.Message)
    Write-Line ''
    Write-Line 'If login failed: use the email/password you use in SwimIQ.'
    Write-Line 'Or add demo@swimiqapp.com in Supabase (seed_demo_master.sql).'
    Write-Line ('Report saved: ' + $outFile)
    Write-Host ''
    Write-Host 'FAILED - see GEMINI-DIAGNOSIS.txt' -ForegroundColor Red
    exit 1
}
