# SwimIQ Chrome launcher (Kara Williams / OneDrive / spaces / objective_c hooks)
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'swimiq-windows-paths.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$ensureScript = Join-Path $PSScriptRoot 'ensure-video-db-fix.ps1'
if (Test-Path -LiteralPath $ensureScript) {
    try {
        . $ensureScript
        Ensure-VideoDbFix -Root $repoRoot
    } catch {
        Write-Host "Note: could not write video DB fix files: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Launch Chrome' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot $PSScriptRoot -CleanDartTool
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

$envFile = Join-Path $paths.WorkDir '.env'
$exampleFile = Join-Path $paths.WorkDir '.env.example'

if (-not (Test-Path -LiteralPath $envFile)) {
    if (Test-Path -LiteralPath $exampleFile) {
        Copy-Item $exampleFile $envFile
    }
    Write-Host 'Created .env - add Supabase URL + anon key, save, run again.' -ForegroundColor Yellow
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
    Write-Host 'ERROR: Edit .env with real Supabase keys.' -ForegroundColor Red
    notepad $envFile
    Read-Host 'Press Enter to close'
    exit 1
}

Write-Host 'Pulling fixed app branch (dashboard + Elite Video)...' -ForegroundColor Yellow
Push-Location (Split-Path $paths.WorkDir -Parent)
try {
    git fetch origin cursor/elite-video-on-dashboard-b7ef 2>$null
    git checkout -f cursor/elite-video-on-dashboard-b7ef 2>$null
    git reset --hard origin/cursor/elite-video-on-dashboard-b7ef 2>$null
    Write-Host '[OK] On cursor/elite-video-on-dashboard-b7ef' -ForegroundColor Green
} catch {
    Write-Host '[WARN] Git update skipped - using local copy.' -ForegroundColor Yellow
} finally {
    Pop-Location
}

# Elite Video Lab is the product Video experience (old Gemini tab path stays off).
try {
    $envLines = Get-Content -LiteralPath $envFile
    $out = @()
    $foundV2 = $false
    $foundApi = $false
    $foundDual = $false
    foreach ($line in $envLines) {
        if ($line -match '^\s*VIDEO_ENGINE_V2\s*=') {
            $out += 'VIDEO_ENGINE_V2=true'
            $foundV2 = $true
        } elseif ($line -match '^\s*ANALYSIS_API_BASE_URL\s*=') {
            $out += 'ANALYSIS_API_BASE_URL=http://127.0.0.1:8080'
            $foundApi = $true
        } elseif ($line -match '^\s*VIDEO_ENGINE_V2_DUAL_RUN\s*=') {
            $out += 'VIDEO_ENGINE_V2_DUAL_RUN=false'
            $foundDual = $true
        } else {
            $out += $line
        }
    }
    if (-not $foundV2) { $out += 'VIDEO_ENGINE_V2=true' }
    if (-not $foundApi) { $out += 'ANALYSIS_API_BASE_URL=http://127.0.0.1:8080' }
    if (-not $foundDual) { $out += 'VIDEO_ENGINE_V2_DUAL_RUN=false' }
    # ASCII avoids UTF-8 BOM, which breaks --dart-define-from-file parsing.
    Set-Content -LiteralPath $envFile -Value $out -Encoding ascii
    Write-Host '[OK] VIDEO_ENGINE_V2=true (Elite Video Lab)' -ForegroundColor Green
    Write-Host '     ANALYSIS_API_BASE_URL=http://127.0.0.1:8080' -ForegroundColor Green
} catch {
    Write-Host '[WARN] Could not update VIDEO_ENGINE_V2 in .env' -ForegroundColor Yellow
}

# START-SWIMIQ-WITH-ELITE already started Elite. Only ping health here - never kill/restart.
$eliteWait = Join-Path $PSScriptRoot 'start-elite-and-wait.ps1'
if (Test-Path -LiteralPath $eliteWait) {
    Write-Host ''
    Write-Host 'Confirming Elite analysis server is still up...' -ForegroundColor Cyan
    # Nested process so CheckOnly "exit 0" does not kill this Chrome launcher.
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $eliteWait -CheckOnly
    if ($LASTEXITCODE -ne 0) {
        Write-Host ''
        Write-Host 'ERROR: Elite server is not reachable at http://127.0.0.1:8080/health' -ForegroundColor Red
        Write-Host 'Run START-SWIMIQ-WITH-ELITE.bat and leave the Elite window open.' -ForegroundColor Red
        Read-Host 'Press Enter to close'
        exit 1
    }
}

Write-Host 'Checking Aspyn login icon (assets\branding\icon.png)...' -ForegroundColor Cyan
$brandDir = Join-Path $paths.WorkDir 'assets\branding'
$loginIcon = Join-Path $brandDir 'icon.png'
$logoIcon = Join-Path $brandDir 'logo.png'
$legacyIcon = Join-Path $brandDir 'swimiq_icon.png'
$webFav = Join-Path $paths.WorkDir 'web\favicon.png'
$web512 = Join-Path $paths.WorkDir 'web\icons\Icon-512.png'
$web192 = Join-Path $paths.WorkDir 'web\icons\Icon-192.png'
New-Item -ItemType Directory -Force -Path $brandDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $paths.WorkDir 'web\icons') | Out-Null

# Prefer a real PNG (>= 20KB). Tiny/corrupt files cause the triangle fallback.
function Test-GoodPng([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    return ((Get-Item -LiteralPath $path).Length -ge 20000)
}

if (-not (Test-GoodPng $loginIcon)) {
    if (Test-GoodPng $logoIcon) {
        Copy-Item -LiteralPath $logoIcon -Destination $loginIcon -Force
        Write-Host 'OK  Copied logo.png -> icon.png for login' -ForegroundColor Green
    } elseif (Test-GoodPng $legacyIcon) {
        Copy-Item -LiteralPath $legacyIcon -Destination $loginIcon -Force
        Copy-Item -LiteralPath $legacyIcon -Destination $logoIcon -Force
        Write-Host 'OK  Copied swimiq_icon.png -> icon.png for login' -ForegroundColor Green
    } else {
        # Do not block Elite bring-up on a logo. Prefer any existing PNG, else continue.
        $fallback = $null
        foreach ($cand in @($web512, $web192, $webFav, $logoIcon, $legacyIcon)) {
            if (Test-Path -LiteralPath $cand) { $fallback = $cand; break }
        }
        if ($fallback) {
            Copy-Item -LiteralPath $fallback -Destination $loginIcon -Force
            Write-Host "[WARN] Login icon was small/missing - using $fallback for now." -ForegroundColor Yellow
        } else {
            Write-Host '[WARN] Login icon missing - continuing anyway (Elite still works).' -ForegroundColor Yellow
            Write-Host '       Later: drag a 512x512 PNG onto COPY-LOGO.bat if you want Aspyn branding.' -ForegroundColor Yellow
        }
    }
}

# Keep web favicons in sync when we have a usable login icon.
if (Test-Path -LiteralPath $loginIcon) {
    Copy-Item -LiteralPath $loginIcon -Destination $logoIcon -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath $loginIcon -Destination $webFav -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath $loginIcon -Destination $web512 -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath $loginIcon -Destination $web192 -Force -ErrorAction SilentlyContinue
    $iconBytes = (Get-Item -LiteralPath $loginIcon).Length
    Write-Host ("OK  Login icon ready ({0} bytes): {1}" -f $iconBytes, $loginIcon) -ForegroundColor Green
}

Write-Host 'Cleaning old build cache (fixes objective_c hook errors)...' -ForegroundColor Yellow
Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat

Write-Host ''
Write-Host '############################################' -ForegroundColor Yellow
Write-Host ' CLOSE every swimiqapp.com tab first.' -ForegroundColor Yellow
Write-Host ' Fixed app address must be 127.0.0.1' -ForegroundColor Yellow
Write-Host ' If address bar says swimiqapp.com - WRONG TAB' -ForegroundColor Yellow
Write-Host ' Old workstation banner = old website files' -ForegroundColor Yellow
Write-Host '############################################' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Clearing old Flutter web ports (fixes errno 10048)...' -ForegroundColor Cyan
$killWeb = Join-Path $PSScriptRoot 'kill-flutter-web-port.ps1'
if (Test-Path -LiteralPath $killWeb) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $killWeb
}

Write-Host 'Building app on 127.0.0.1 - this can take 2-4 minutes the first time...' -ForegroundColor Cyan
Write-Host 'Chrome will open ONLY after the app is ready (not a blank page).' -ForegroundColor Yellow
Write-Host ''

& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) {
    Read-Host 'Press Enter to close'
    exit $LASTEXITCODE
}

function Find-ChromeExe {
    $candidates = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    $cmd = Get-Command chrome -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Open-LocalApp([string]$url) {
    $chrome = Find-ChromeExe
    # Cache-bust so an old blank tab does not stick.
    $stamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $openUrl = $url
    if ($openUrl -notmatch '\-') { $openUrl = "$openUrl/-v=$stamp" }
    if ($chrome) {
        Start-Process -FilePath $chrome -ArgumentList @(
            '--new-window',
            '--disable-http-cache',
            $openUrl
        )
        return $true
    }
    try {
        Start-Process $openUrl
        return $true
    } catch {
        return $false
    }
}

function Test-FlutterWebReady([string]$baseUrl) {
    $pathsToTry = @(
        "$baseUrl/main.dart.js",
        "$baseUrl/flutter_bootstrap.js",
        "$baseUrl/flutter.js",
        "$baseUrl/"
    )
    foreach ($p in $pathsToTry) {
        try {
            $r = Invoke-WebRequest -UseBasicParsing -Uri $p -TimeoutSec 4
            if ($r.StatusCode -ne 200) { continue }
            $body = [string]$r.Content
            if ($p -match 'main\.dart\.js|flutter_bootstrap\.js|flutter\.js') {
                if ($body.Length -gt 200) { return $true }
            } elseif ($body -match 'flutter|main\.dart\.js|flutter_bootstrap') {
                return $true
            }
        } catch {}
    }
    return $false
}

# Serve with web-server, WAIT until ready, THEN open Chrome once.
$chromeExe = Find-ChromeExe
$webPorts = @(7357, 7358, 7359, 7360)
$code = 1
$opened = $false

foreach ($webPort in $webPorts) {
    $url = "http://127.0.0.1:$webPort"
    Write-Host ("Starting app server at {0} ..." -f $url) -ForegroundColor Cyan
    if (Test-Path -LiteralPath $killWeb) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $killWeb
    }

    $flutterBatSafe = $paths.FlutterBat.Replace("'", "''")
    $envFileSafe = $envFile.Replace("'", "''")
    $argList = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-Command',
        ("& '{0}' run -d web-server --web-hostname=127.0.0.1 --web-port={1} --dart-define-from-file='{2}'" -f $flutterBatSafe, $webPort, $envFileSafe)
    )
    $flutterProc = Start-Process -FilePath 'powershell.exe' `
        -ArgumentList $argList `
        -WorkingDirectory $paths.WorkDir `
        -PassThru `
        -WindowStyle Normal

    Write-Host 'Waiting for app compile (up to 5 minutes). Dots = still working...' -ForegroundColor Cyan
    $deadline = (Get-Date).AddMinutes(5)
    $ready = $false
    while ((Get-Date) -lt $deadline) {
        if ($flutterProc.HasExited) {
            Write-Host ''
            Write-Host ("[FAIL] App server exited early (code {0})." -f $flutterProc.ExitCode) -ForegroundColor Red
            break
        }
        if (Test-FlutterWebReady $url) {
            $ready = $true
            break
        }
        Write-Host -NoNewline '.'
        Start-Sleep -Seconds 4
    }
    Write-Host ''

    if (-not $ready) {
        Write-Host ("Port {0} not ready in time. Trying next..." -f $webPort) -ForegroundColor Yellow
        try { Stop-Process -Id $flutterProc.Id -Force -ErrorAction SilentlyContinue } catch {}
        Start-Sleep -Seconds 1
        continue
    }

    Write-Host '[OK] App is ready. Opening Chrome now...' -ForegroundColor Green
    Write-Host ("Address must be: {0}" -f $url) -ForegroundColor Green
    if (Open-LocalApp $url) {
        $opened = $true
        Write-Host 'If Chrome shows login - you are good.' -ForegroundColor Green
        Write-Host 'If Chrome is still blank: press F5 once.' -ForegroundColor Yellow
    } else {
        Write-Host "[FAIL] Could not open Chrome. Open this yourself: $url" -ForegroundColor Red
    }

    Write-Host ''
    Write-Host 'Leave this window open while you use SwimIQ.' -ForegroundColor Yellow
    Write-Host 'Press Ctrl+C in the Flutter window to stop the app server later.' -ForegroundColor Yellow
    try {
        Wait-Process -Id $flutterProc.Id
        $code = $flutterProc.ExitCode
        if ($null -eq $code) { $code = 0 }
    } catch {
        $code = 0
    }
    break
}

if (-not $opened) {
    Write-Host 'Trying Flutter -> Chrome direct launch as last fallback...' -ForegroundColor Yellow
    if (Test-Path -LiteralPath $killWeb) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $killWeb
    }
    & $paths.FlutterBat run -d chrome `
        --web-hostname=127.0.0.1 `
        --web-port=7357 `
        --dart-define-from-file=$envFile
    $code = $LASTEXITCODE
}

Write-Host ''
if ($code -ne 0 -and -not $opened) {
    Write-Host 'Launch failed.' -ForegroundColor Red
    Write-Host 'Do this:' -ForegroundColor Yellow
    Write-Host '  1) Close EVERY Chrome window' -ForegroundColor Yellow
    Write-Host '  2) Run START-SWIMIQ-WITH-ELITE.bat again' -ForegroundColor Yellow
    Write-Host '  3) Address bar must say 127.0.0.1  (not swimiqapp.com)' -ForegroundColor Yellow
} else {
    Write-Host 'App session ended.' -ForegroundColor Green
}
Read-Host 'Press Enter to close'
exit $code
