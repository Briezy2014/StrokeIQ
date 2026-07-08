# ============================================================
# SwimIQ — ONE FILE Chrome launcher (Kara Williams / Windows)
# Double-click SWIMIQ-CHROME-NOW.bat  OR  run this in PowerShell
# ============================================================
$ErrorActionPreference = 'Stop'

function Get-SubstMap {
    $map = @{}
    cmd /c subst 2>$null | ForEach-Object {
        if ($_ -match '=>') {
            $left, $right = $_ -split '=>', 2
            $left = $left.Trim()
            $right = $right.Trim()
            if ($left -match '^([A-Z]):') {
                $map[$matches[1]] = $right
            }
        }
    }
    return $map
}

function Get-RealPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }
    $p = $Path.TrimEnd('\')
    if ($p -match '^[A-Z]:$') {
        $m = Get-SubstMap
        $letter = $p[0]
        if ($m.ContainsKey($letter)) { return $m[$letter] }
    }
    if (Test-Path -LiteralPath $p) {
        return (Get-Item -LiteralPath $p).FullName
    }
    return $p
}

function MapDrive([string]$Letter, [string]$Target) {
    $target = (Get-RealPath $Target).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $target)) {
        throw "Folder not found for ${Letter}: drive:`n$target"
    }
    $m = Get-SubstMap
    if ($m.ContainsKey($Letter) -and ($m[$Letter].TrimEnd('\') -ieq $target)) {
        Write-Host "OK  ${Letter}: already -> $target" -ForegroundColor Green
        return
    }
    if ($m.ContainsKey($Letter)) {
        cmd /c "subst ${Letter}: /D" | Out-Null
    }
    $q = $target -replace '"', '""'
    $result = cmd /c "subst ${Letter}: `"$q`""
    if ($LASTEXITCODE -ne 0) {
        throw "Could not map ${Letter}: to:`n$target"
    }
    Write-Host "OK  ${Letter}: -> $target" -ForegroundColor Green
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Chrome NOW' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

# Always step off S: before remapping drives (fixes subst crash)
Set-Location C:\

$scriptDir = $PSScriptRoot
if ($scriptDir -match '^[A-Z]:\\') {
    $scriptDir = Get-RealPath $scriptDir
}
$swimiqDir = Get-RealPath (Join-Path $scriptDir '')
if (Split-Path -Leaf $swimiqDir) -ne 'swimiq') {
    $swimiqDir = Get-RealPath (Join-Path $scriptDir 'swimiq')
}
$strokeDir = Get-RealPath (Split-Path -Parent $swimiqDir)

Write-Host "StrokeIQ: $strokeDir"
Write-Host "SwimIQ:   $swimiqDir"
Write-Host ''

# Find Flutter
$flutterDir = $null
foreach ($c in @("$env:USERPROFILE\flutter", 'C:\flutter', 'C:\src\flutter')) {
    $p = Get-RealPath $c
    if (Test-Path -LiteralPath "$p\bin\flutter.bat") { $flutterDir = $p; break }
}
if (-not $flutterDir) {
    $fc = Get-Command flutter -ErrorAction SilentlyContinue
    if ($fc) {
        $p = Get-RealPath (Split-Path (Split-Path $fc.Source -Parent) -Parent)
        if (Test-Path -LiteralPath "$p\bin\flutter.bat") { $flutterDir = $p }
    }
}
if (-not $flutterDir) {
    Write-Host 'ERROR: Flutter not found.' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}
Write-Host "Flutter:  $flutterDir"
Write-Host ''

# Map drives (no spaces in paths Flutter/Dart use)
MapDrive -Letter 'S' -Target $strokeDir
if ($flutterDir -match ' ') {
    MapDrive -Letter 'F' -Target $flutterDir
    $flutterBat = 'F:\bin\flutter.bat'
} else {
    $flutterBat = Join-Path $flutterDir 'bin\flutter.bat'
}

$pubCache = 'S:\pub-cache'
New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
$env:PUB_CACHE = $pubCache
[Environment]::SetEnvironmentVariable('PUB_CACHE', $pubCache, 'User')
$env:Path = "$(Split-Path $flutterBat -Parent);$env:Path"

Set-Location 'S:\swimiq'
Write-Host "OK  Working in: $(Get-Location)" -ForegroundColor Green
Write-Host "OK  PUB_CACHE: $pubCache" -ForegroundColor Green
Write-Host ''

# .env
$envFile = 'S:\swimiq\.env'
if (-not (Test-Path $envFile)) {
    if (Test-Path 'S:\swimiq\.env.example') { Copy-Item 'S:\swimiq\.env.example' $envFile }
    Write-Host 'Created .env — paste Supabase keys, save, run this again.' -ForegroundColor Yellow
    notepad $envFile
    Read-Host 'Press Enter'; exit 1
}

$url = $null; $key = $null
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim() }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim() }
}
$url = $url -replace 'https:https//','https://' -replace 'https//','https://'
if ($url -and $url -notmatch '^https://') { $url = "https://$url" }

if (-not $url -or -not $key) {
    Write-Host 'ERROR: .env needs SUPABASE_URL and SUPABASE_ANON_KEY' -ForegroundColor Red
    notepad $envFile
    Read-Host 'Press Enter'; exit 1
}

Write-Host 'Starting Chrome — 1-2 minutes...' -ForegroundColor Cyan
& $flutterBat pub get
if ($LASTEXITCODE -ne 0) { Read-Host 'Press Enter'; exit $LASTEXITCODE }

& $flutterBat run -d chrome --dart-define=SUPABASE_URL=$url --dart-define=SUPABASE_ANON_KEY=$key
Read-Host 'Press Enter to close'
exit $LASTEXITCODE
