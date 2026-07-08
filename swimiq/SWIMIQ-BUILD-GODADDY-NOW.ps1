# SwimIQ — ONE FILE GoDaddy web build (Kara Williams / Windows)
# Double-click SWIMIQ-BUILD-GODADDY-NOW.bat after Chrome preview looks good
$ErrorActionPreference = 'Stop'

function Get-SubstMap {
    $map = @{}
    cmd /c subst 2>$null | ForEach-Object {
        if ($_ -match '=>') {
            $left, $right = $_ -split '=>', 2
            if ($left.Trim() -match '^([A-Z]):') { $map[$matches[1]] = $right.Trim() }
        }
    }
    return $map
}

function Resolve-PhysicalPath([string]$Path) {
    $p = $Path.TrimEnd('\')
    $m = Get-SubstMap
    if ($p -match '^([A-Z]):\\?(.*)$') {
        $letter = $matches[1]; $rest = $matches[2]
        if ($m.ContainsKey($letter)) {
            if ([string]::IsNullOrEmpty($rest)) { return $m[$letter] }
            return Join-Path $m[$letter] $rest
        }
    }
    if (Test-Path -LiteralPath $p) { return (Get-Item -LiteralPath $p).FullName }
    return $p
}

function MapDrive([string]$Letter, [string]$Target) {
    $target = (Resolve-PhysicalPath $Target).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $target)) { throw "Not found: $target" }
    $m = Get-SubstMap
    if ($m.ContainsKey($Letter) -and ($m[$Letter].TrimEnd('\') -ieq $target)) { return }
    if ($m.ContainsKey($Letter)) { cmd /c "subst ${Letter}: /D" | Out-Null }
    cmd /c "subst ${Letter}: `"$($target -replace '"','""')`"" | Out-Null
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Build for GoDaddy' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

Set-Location C:\
$swimiqDir = Resolve-PhysicalPath $PSScriptRoot
$strokeDir = Resolve-PhysicalPath (Split-Path -Parent $swimiqDir)

$flutterDir = $null
foreach ($c in @("$env:USERPROFILE\flutter", 'C:\flutter', 'C:\src\flutter')) {
    $p = Resolve-PhysicalPath $c
    if (Test-Path -LiteralPath "$p\bin\flutter.bat") { $flutterDir = $p; break }
}
if (-not $flutterDir) {
    Write-Host 'ERROR: Flutter not found.' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

MapDrive 'S' $strokeDir
if ($flutterDir -match ' ') {
    MapDrive 'F' $flutterDir
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

$envFile = 'S:\swimiq\.env'
if (-not (Test-Path $envFile)) {
    Write-Host 'ERROR: Missing S:\swimiq\.env' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

$url = $null; $key = $null
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim() }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim() }
}
$url = $url -replace 'https:https//','https://' -replace 'https//','https://'
if ($url -and $url -notmatch '^https://') { $url = "https://$url" }
if (-not $url -or -not $key -or $url -match 'your-project') {
    Write-Host 'ERROR: .env needs SUPABASE_URL and SUPABASE_ANON_KEY' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

Write-Host 'Building release web app (3-5 minutes)...' -ForegroundColor Cyan
& $flutterBat clean
& $flutterBat pub get
if ($LASTEXITCODE -ne 0) { Read-Host 'Press Enter'; exit $LASTEXITCODE }

& $flutterBat build web --release `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key

if ($LASTEXITCODE -ne 0) {
    Write-Host 'BUILD FAILED — do not upload to GoDaddy' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

if (-not (Test-Path 'S:\swimiq\build\web\main.dart.js')) {
    Write-Host 'BUILD FAILED — missing main.dart.js' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

$htaccess = 'S:\swimiq\web\.htaccess'
if (Test-Path $htaccess) {
    Copy-Item $htaccess 'S:\swimiq\build\web\.htaccess' -Force
    Write-Host 'OK  Added .htaccess for GoDaddy' -ForegroundColor Green
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host ' BUILD DONE' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host ' Upload ALL files in:' -ForegroundColor Green
Write-Host '   S:\swimiq\build\web\' -ForegroundColor Green
Write-Host ' to GoDaddy public_html (keep cgi-bin)' -ForegroundColor Green
Write-Host ' Then visit https://swimiqapp.com in Incognito' -ForegroundColor Green
Read-Host 'Press Enter to close'
