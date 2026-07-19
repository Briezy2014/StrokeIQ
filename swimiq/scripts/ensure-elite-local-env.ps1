# Prepares services/video_analysis/.env for local Windows Elite runs.
# ASCII-only on purpose. Windows PowerShell 5.1 misreads UTF-8 dashes/ellipsis.
$ErrorActionPreference = 'Continue'

function Read-EnvMap([string]$path) {
    $map = @{}
    if (-not (Test-Path -LiteralPath $path)) { return $map }
    Get-Content -LiteralPath $path | ForEach-Object {
        if ($_ -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.*)$') {
            $val = $matches[2].Trim()
            # Strip wrapping quotes copied from some editors.
            if (($val.StartsWith('"') -and $val.EndsWith('"')) -or ($val.StartsWith("'") -and $val.EndsWith("'"))) {
                $val = $val.Substring(1, $val.Length - 2)
            }
            # Strip unquoted trailing comments: KEY=value # note
            if ($val -notmatch '^\s*["'']' -and $val.Contains('#')) {
                $val = ($val -split '#', 2)[0].Trim()
            }
            $map[$matches[1]] = $val
        }
    }
    return $map
}

function Is-Configured([string]$value, [string[]]$badMarkers) {
    if ([string]::IsNullOrWhiteSpace($value)) { return $false }
    $lower = $value.ToLowerInvariant()
    foreach ($m in $badMarkers) {
        if ($lower.Contains($m)) { return $false }
    }
    return $true
}

function Write-EnvFile([string]$path, $map) {
    $lines = foreach ($k in ($map.Keys | Sort-Object)) {
        "$k=$($map[$k])"
    }
    Set-Content -LiteralPath $path -Value $lines -Encoding ascii
}

function Import-FlutterKeys([hashtable]$map, [string[]]$flutterCandidates, [string[]]$geminiBad, [string]$eliteEnvPath) {
    $flutterUrl = $null
    $flutterAnon = $null
    $flutterSource = $null
    foreach ($candidate in $flutterCandidates) {
        if (-not (Test-Path -LiteralPath $candidate)) { continue }
        $flutterMap = Read-EnvMap $candidate
        if (Is-Configured ([string]$flutterMap['SUPABASE_URL']) @('your-project')) {
            $flutterUrl = [string]$flutterMap['SUPABASE_URL']
        }
        if (Is-Configured ([string]$flutterMap['SUPABASE_ANON_KEY']) @('your-supabase', 'your_anon', 'paste_')) {
            $flutterAnon = [string]$flutterMap['SUPABASE_ANON_KEY']
        }
        if ($flutterUrl -and $flutterAnon) {
            $flutterSource = $candidate
            break
        }
    }
    if ($flutterUrl) { $map['SUPABASE_URL'] = $flutterUrl }
    if ($flutterAnon) { $map['SUPABASE_ANON_KEY'] = $flutterAnon }

    $geminiKey = $null
    $geminiSource = $null
    foreach ($candidate in $flutterCandidates) {
        if (-not (Test-Path -LiteralPath $candidate)) { continue }
        $dupCount = @(Get-Content -LiteralPath $candidate | Where-Object { $_ -match '^\s*GEMINI_API_KEY\s*=' }).Count
        if ($dupCount -gt 1) {
            Write-Host "[WARN] $candidate has $dupCount GEMINI_API_KEY lines - using the LAST one only." -ForegroundColor Yellow
            Write-Host '       Keep only ONE GEMINI_API_KEY= line in swimiq\.env' -ForegroundColor Yellow
        }
        $flutterMap = Read-EnvMap $candidate
        $candidateKey = [string]$flutterMap['GEMINI_API_KEY']
        if (Is-Configured $candidateKey $geminiBad) {
            $geminiKey = $candidateKey
            $geminiSource = $candidate
            break
        }
    }
    if (-not $geminiKey -and (Is-Configured ([string]$env:GEMINI_API_KEY) $geminiBad)) {
        $geminiKey = [string]$env:GEMINI_API_KEY
        $geminiSource = 'process environment'
    }
    if (-not $geminiKey -and (Is-Configured ([string]$map['GEMINI_API_KEY']) $geminiBad)) {
        $geminiKey = [string]$map['GEMINI_API_KEY']
        $geminiSource = $eliteEnvPath
    }
    # Coaching always uses SwimIQ Elite coach on this PC (100% path).
    # Gemini is optional enhance only and stays OFF so reports never fail on API issues.
    $map['GEMINI_REPORT_ENABLED'] = 'false'
    if ($geminiKey) {
        $map['GEMINI_API_KEY'] = $geminiKey
    }

    return @{
        FlutterSource = $flutterSource
        GeminiKey     = $geminiKey
        GeminiSource  = $geminiSource
    }
}

function Apply-EliteDefaults([hashtable]$map) {
    $map['ENGINE_VERSION'] = 'elite-0.9.0'
    $map['SUPABASE_AUTH_REQUIRED'] = 'false'
    $map['CORS_ALLOW_ORIGINS'] = '*'
    $map['VIDEO_ENGINE_NAME'] = 'video_engine_v2'
    $map['POSE_ENABLED'] = 'false'
    $map['BUTTERFLY_ANALYSIS_ENABLED'] = 'false'
    $map['UNDERWATER_ANALYSIS_ENABLED'] = 'false'
    $map['TURN_ANALYSIS_ENABLED'] = 'false'
    $map['FINISH_ANALYSIS_ENABLED'] = 'false'
    $map['MAX_TARGET_LOST_FRAMES'] = '120'
    $map['MIN_USABLE_TARGET_COVERAGE'] = '0.08'
    $map['MIN_DETECTION_CONFIDENCE'] = '0.25'
    $map['TRACKING_CONFIDENCE_THRESHOLD'] = '0.30'
    $map['MAX_LOST_FRAMES'] = '30'
    $map['FRAME_PROCESSING_INTERVAL'] = '8'
    $map['MAX_ANALYSIS_DURATION_S'] = '15'
    $map['ANNOTATED_FRAME_STRIDE'] = '4'
    $map['MAX_ACTIVE_TRACKS'] = '8'
    $map['GEMINI_TIMEOUT_S'] = '12'
    $map['GEMINI_MAX_REGENERATE_ATTEMPTS'] = '1'
    if (-not $map.ContainsKey('FFMPEG_PATH') -or [string]::IsNullOrWhiteSpace([string]$map['FFMPEG_PATH'])) {
        $map['FFMPEG_PATH'] = 'ffmpeg'
    }
    if (-not $map.ContainsKey('FFPROBE_PATH') -or [string]::IsNullOrWhiteSpace([string]$map['FFPROBE_PATH'])) {
        $map['FFPROBE_PATH'] = 'ffprobe'
    }
}

$videoDir = $args[0]
if ([string]::IsNullOrWhiteSpace($videoDir)) {
    $videoDir = (Get-Location).Path
}
if (-not (Test-Path -LiteralPath $videoDir)) {
    Write-Host "[FAIL] Video dir not found: $videoDir" -ForegroundColor Red
    exit 1
}
$videoDir = (Resolve-Path -LiteralPath $videoDir).Path
$envFile = Join-Path $videoDir '.env'
$exampleFile = Join-Path $videoDir '.env.example'

# repo/services/video_analysis -> repo root
$repoRoot = Split-Path (Split-Path $videoDir -Parent) -Parent

$flutterCandidates = @(
    (Join-Path $repoRoot 'swimiq\.env'),
    'C:\SwimIQWork\swimiq\.env',
    (Join-Path $env:USERPROFILE 'OneDrive\Desktop\StrokeIQ\swimiq\.env'),
    (Join-Path $env:USERPROFILE 'Desktop\StrokeIQ\swimiq\.env')
)

if (-not (Test-Path -LiteralPath $envFile)) {
    if (Test-Path -LiteralPath $exampleFile) {
        Copy-Item -LiteralPath $exampleFile -Destination $envFile -Force
        Write-Host '[OK] Created services\video_analysis\.env from example'
    } else {
        New-Item -ItemType File -Path $envFile -Force | Out-Null
        Write-Host '[OK] Created empty services\video_analysis\.env'
    }
}

$geminiBad = @('paste_', 'your-', 'changeme', 'your_key', 'xxx')
$map = Read-EnvMap $envFile
$importInfo = Import-FlutterKeys $map $flutterCandidates $geminiBad $envFile
Apply-EliteDefaults $map
Write-EnvFile $envFile $map

$urlOk = Is-Configured ([string]$map['SUPABASE_URL']) @('your-project')
$anonOk = Is-Configured ([string]$map['SUPABASE_ANON_KEY']) @('your-supabase', 'your_anon', 'paste_')
$serviceOk = Is-Configured ([string]$map['SUPABASE_SERVICE_ROLE_KEY']) @('paste_', 'your-')

if (-not $urlOk -or -not $anonOk) {
    Write-Host ''
    Write-Host '[FAIL] Elite server needs Supabase URL + anon key to download videos.' -ForegroundColor Red
    Write-Host 'Looked for Flutter .env in:' -ForegroundColor Yellow
    foreach ($c in $flutterCandidates) { Write-Host "  - $c" }
    $flutterPreferred = Join-Path $repoRoot 'swimiq\.env'
    $editPath = $envFile
    if (Test-Path -LiteralPath $flutterPreferred) { $editPath = $flutterPreferred }
    Write-Host "Write them into: $editPath" -ForegroundColor Yellow
    Write-Host 'Save Notepad, close it, and this script will re-check once.' -ForegroundColor Yellow
    if (Test-Path -LiteralPath $editPath) {
        Start-Process -FilePath 'notepad.exe' -ArgumentList "`"$editPath`"" -Wait
        $map = Read-EnvMap $envFile
        $importInfo = Import-FlutterKeys $map $flutterCandidates $geminiBad $envFile
        Apply-EliteDefaults $map
        Write-EnvFile $envFile $map
        $urlOk = Is-Configured ([string]$map['SUPABASE_URL']) @('your-project')
        $anonOk = Is-Configured ([string]$map['SUPABASE_ANON_KEY']) @('your-supabase', 'your_anon', 'paste_')
        if ($urlOk -and $anonOk) {
            Write-Host '[OK] Keys look good after Notepad edit - continuing.' -ForegroundColor Green
        } else {
            Write-Host '[FAIL] Keys still missing after Notepad. Fix swimiq\.env then run START-SWIMIQ-WITH-ELITE.bat once.' -ForegroundColor Red
            exit 2
        }
    } else {
        exit 2
    }
}

Write-Host '[OK] Local analysis .env ready for storage download.' -ForegroundColor Green
if ($importInfo.FlutterSource) {
    Write-Host "     Copied Supabase URL/anon from: $($importInfo.FlutterSource)" -ForegroundColor Green
}
Write-Host '     SUPABASE_URL: set' -ForegroundColor Green
Write-Host '     SUPABASE_ANON_KEY: set' -ForegroundColor Green
if ($serviceOk) {
    Write-Host '     SUPABASE_SERVICE_ROLE_KEY: set' -ForegroundColor Green
} else {
    Write-Host '     SUPABASE_SERVICE_ROLE_KEY: not set (OK - uses signed-in session token)' -ForegroundColor Yellow
}
$geminiKey = $importInfo.GeminiKey
$geminiSource = $importInfo.GeminiSource
Write-Host '     Coaching: SwimIQ Elite coach ALWAYS ON (does not need Gemini)' -ForegroundColor Green
$geminiOk = Is-Configured ([string]$map['GEMINI_API_KEY']) $geminiBad
if ($geminiOk) {
    Write-Host '     GEMINI_API_KEY: present but OFF (optional only; reports never wait on it)' -ForegroundColor Green
} else {
    Write-Host '     GEMINI_API_KEY: not set (OK - Elite coaching still runs every time)' -ForegroundColor Green
}
exit 0
