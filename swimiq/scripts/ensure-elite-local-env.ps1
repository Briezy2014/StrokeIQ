# Prepares services/video_analysis/.env for local Windows Elite runs.
$ErrorActionPreference = 'Stop'

$videoDir = $args[0]
if ([string]::IsNullOrWhiteSpace($videoDir)) {
    $videoDir = (Get-Location).Path
}
$videoDir = (Resolve-Path -LiteralPath $videoDir).Path
$envFile = Join-Path $videoDir '.env'
$exampleFile = Join-Path $videoDir '.env.example'

# repo/services/video_analysis → repo/swimiq/.env
$repoRoot = Split-Path (Split-Path $videoDir -Parent) -Parent
$flutterEnv = Join-Path $repoRoot 'swimiq\.env'

if (-not (Test-Path -LiteralPath $envFile)) {
    if (Test-Path -LiteralPath $exampleFile) {
        Copy-Item -LiteralPath $exampleFile -Destination $envFile -Force
        Write-Host '[OK] Created services\video_analysis\.env from example'
    } else {
        New-Item -ItemType File -Path $envFile -Force | Out-Null
        Write-Host '[OK] Created empty services\video_analysis\.env'
    }
}

$map = @{}
Get-Content -LiteralPath $envFile | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.*)$') {
        $map[$matches[1]] = $matches[2]
    }
}

if (Test-Path -LiteralPath $flutterEnv) {
    Get-Content -LiteralPath $flutterEnv | ForEach-Object {
        if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') {
            $map['SUPABASE_URL'] = $matches[1].Trim()
        }
        if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') {
            $map['SUPABASE_ANON_KEY'] = $matches[1].Trim()
        }
    }
}

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
Write-Host '[OK] Local analysis .env ready (auth off for Windows desktop).' -ForegroundColor Green
