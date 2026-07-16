# Syncs analyze-swim-video edge function + diagnose script for KARA-GEMINI-FIX-NOW.bat
# Works when git root is StrokeIQ (parent) OR swimiq (repo root).
# ASCII-only strings - avoids PowerShell [bracket] parse errors on Windows.
param(
    [string]$SwimIqRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$Branch = 'cursor/dashboard-rope-schedule-fix-17e8',
    [string]$RequiredVersion = '2026-gemini-sync-v9'
)

$ErrorActionPreference = 'Continue'
$SwimIqRoot = (Resolve-Path -LiteralPath $SwimIqRoot).Path
$indexPath = Join-Path $SwimIqRoot 'supabase\functions\analyze-swim-video\index.ts'
$diagPath = Join-Path $SwimIqRoot 'scripts\diagnose-gemini.js'

function Test-StreamVersion {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    return (Select-String -LiteralPath $Path -Pattern $RequiredVersion -Quiet)
}

function Sync-FromGit {
    $gitRoot = git -C $SwimIqRoot rev-parse --show-toplevel 2>$null
    if (-not $gitRoot) { return $false }

    $gitRoot = $gitRoot.Trim()
    Push-Location $gitRoot
    try {
        git fetch origin $Branch 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { return $false }

        $prefix = ''
        if (Test-Path -LiteralPath (Join-Path $gitRoot 'swimiq\supabase\functions\analyze-swim-video\index.ts')) {
            $prefix = 'swimiq/'
        }

        git checkout "origin/$Branch" -- "${prefix}supabase/functions/analyze-swim-video/" 2>&1 | Out-Null
        git checkout "origin/$Branch" -- "${prefix}scripts/diagnose-gemini.js" 2>&1 | Out-Null
        return (Test-StreamVersion -Path $indexPath)
    }
    finally {
        Pop-Location
    }
}

function Sync-FromGitHubRaw {
    $base = "https://raw.githubusercontent.com/Briezy2014/StrokeIQ/$Branch/swimiq"
    $indexUrl = "$base/supabase/functions/analyze-swim-video/index.ts"
    $diagUrl = "$base/scripts/diagnose-gemini.js"

    $indexDir = Split-Path -Parent $indexPath
    New-Item -ItemType Directory -Force -Path $indexDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $diagPath) | Out-Null

    Invoke-WebRequest -Uri $indexUrl -OutFile $indexPath -UseBasicParsing
    Invoke-WebRequest -Uri $diagUrl -OutFile $diagPath -UseBasicParsing
    return (Test-StreamVersion -Path $indexPath)
}

Write-Host ('SwimIQ folder: ' + $SwimIqRoot)
Write-Host ('Need server version: ' + $RequiredVersion)
Write-Host ''

if (Test-StreamVersion -Path $indexPath) {
    Write-Host ('OK - Stream server code already present: ' + $RequiredVersion)
    exit 0
}

Write-Host 'Trying git sync...'
if (Sync-FromGit) {
    Write-Host 'OK - Synced via git.'
    exit 0
}

Write-Host 'Git sync failed - downloading from GitHub (no git needed)...'
try {
    if (Sync-FromGitHubRaw) {
        Write-Host 'OK - Downloaded sync-v9 from GitHub.'
        exit 0
    }
}
catch {
    Write-Host ('ERROR - GitHub download failed: ' + $_.Exception.Message)
    exit 1
}

Write-Host ('ERROR - Downloaded file but version check failed. Need: ' + $RequiredVersion)
exit 1
