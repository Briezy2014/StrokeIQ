# Prepares services/video_analysis/.env for local Windows Elite runs.
$ErrorActionPreference = 'Stop'

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

$videoDir = $args[0]
if ([string]::IsNullOrWhiteSpace($videoDir)) {
    $videoDir = (Get-Location).Path
}
$videoDir = (Resolve-Path -LiteralPath $videoDir).Path
$envFile = Join-Path $videoDir '.env'
$exampleFile = Join-Path $videoDir '.env.example'

# repo/services/video_analysis → repo root
$repoRoot = Split-Path (Split-Path $videoDir -Parent) -Parent

# Flutter .env can live in several path-safe locations on Kara's PC.
$flutterCandidates = @(
    (Join-Path $repoRoot 'swimiq\.env'),
    'C:\SwimIQWork\.env',
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

$map = Read-EnvMap $envFile

$flutterUrl = $null
$flutterAnon = $null
$flutterSource = $null
foreach ($candidate in $flutterCandidates) {
    if (-not (Test-Path -LiteralPath $candidate)) { continue }
    $flutterMap = Read-EnvMap $candidate
    if (Is-Configured ([string]$flutterMap['SUPABASE_URL'] ) @('your-project')) {
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

$map['ENGINE_VERSION'] = 'elite-0.9.0'
$map['SUPABASE_AUTH_REQUIRED'] = 'false'
$map['CORS_ALLOW_ORIGINS'] = '*'
$map['VIDEO_ENGINE_NAME'] = 'video_engine_v2'

if (-not $map.ContainsKey('FFMPEG_PATH') -or [string]::IsNullOrWhiteSpace([string]$map['FFMPEG_PATH'])) {
    $map['FFMPEG_PATH'] = 'ffmpeg'
}
if (-not $map.ContainsKey('FFPROBE_PATH') -or [string]::IsNullOrWhiteSpace([string]$map['FFPROBE_PATH'])) {
    $map['FFPROBE_PATH'] = 'ffprobe'
}

$lines = foreach ($k in ($map.Keys | Sort-Object)) {
    "$k=$($map[$k])"
}
Set-Content -LiteralPath $envFile -Value $lines -Encoding ascii

$urlOk = Is-Configured ([string]$map['SUPABASE_URL']) @('your-project')
$anonOk = Is-Configured ([string]$map['SUPABASE_ANON_KEY']) @('your-supabase', 'your_anon', 'paste_')
$serviceOk = Is-Configured ([string]$map['SUPABASE_SERVICE_ROLE_KEY']) @('paste_', 'your-')

if (-not $urlOk -or -not $anonOk) {
    Write-Host ''
    Write-Host '[FAIL] Elite server needs Supabase URL + anon key to download videos.' -ForegroundColor Red
    Write-Host 'Looked for Flutter .env in:' -ForegroundColor Yellow
    foreach ($c in $flutterCandidates) { Write-Host "  - $c" }
    Write-Host "Write them into: $envFile" -ForegroundColor Yellow
    Write-Host 'Then save, close Notepad, and re-run START-SWIMIQ-WITH-ELITE.bat' -ForegroundColor Yellow
    if (Test-Path -LiteralPath $envFile) { notepad $envFile }
    exit 2
}

Write-Host '[OK] Local analysis .env ready for storage download.' -ForegroundColor Green
if ($flutterSource) {
    Write-Host "     Copied Supabase URL/anon from: $flutterSource" -ForegroundColor Green
}
Write-Host '     SUPABASE_URL: set' -ForegroundColor Green
Write-Host '     SUPABASE_ANON_KEY: set' -ForegroundColor Green
if ($serviceOk) {
    Write-Host '     SUPABASE_SERVICE_ROLE_KEY: set' -ForegroundColor Green
} else {
    Write-Host '     SUPABASE_SERVICE_ROLE_KEY: not set (OK — uses signed-in session token)' -ForegroundColor Yellow
}
exit 0
