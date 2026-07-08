# ============================================================
# SwimIQ — ONE FILE Chrome launcher (Kara Williams / Windows)
# Double-click SWIMIQ-CHROME-NOW.bat
# ============================================================
$ErrorActionPreference = 'Stop'

function Get-SubstMap {
    $map = @{}
    cmd /c subst 2>$null | ForEach-Object {
        if ($_ -match '=>') {
            $left, $right = $_ -split '=>', 2
            if ($left.Trim() -match '^([A-Z]):') {
                $map[$matches[1]] = $right.Trim()
            }
        }
    }
    return $map
}

function Resolve-PhysicalPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }
    $p = $Path.TrimEnd('\')
    $m = Get-SubstMap

    if ($p -match '^([A-Z]):\\?(.*)$') {
        $letter = $matches[1]
        $rest = $matches[2]
        if ($m.ContainsKey($letter)) {
            if ([string]::IsNullOrEmpty($rest)) { return $m[$letter] }
            return Join-Path $m[$letter] $rest
        }
    }

    if (Test-Path -LiteralPath $p) {
        return (Get-Item -LiteralPath $p).FullName
    }
    return $p
}

function MapDrive([string]$Letter, [string]$Target) {
    $target = (Resolve-PhysicalPath $Target).TrimEnd('\')
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
    cmd /c "subst ${Letter}: `"$q`"" | Out-Null
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

# Never remap S: while cwd is on S: (fixes overnight subst crash)
Set-Location C:\

$swimiqDir = Resolve-PhysicalPath $PSScriptRoot
$strokeDir = Resolve-PhysicalPath (Split-Path -Parent $swimiqDir)

Write-Host "StrokeIQ: $strokeDir"
Write-Host "SwimIQ:   $swimiqDir"
Write-Host ''

$flutterDir = $null
foreach ($c in @("$env:USERPROFILE\flutter", 'C:\flutter', 'C:\src\flutter')) {
    $p = Resolve-PhysicalPath $c
    if (Test-Path -LiteralPath "$p\bin\flutter.bat") { $flutterDir = $p; break }
}
if (-not $flutterDir) {
    $fc = Get-Command flutter -ErrorAction SilentlyContinue
    if ($fc) {
        $bin = Split-Path -Parent $fc.Source
        $p = Resolve-PhysicalPath (Join-Path $bin '..')
        if (Test-Path -LiteralPath "$p\bin\flutter.bat") { $flutterDir = $p }
    }
}
if (-not $flutterDir) {
    Write-Host 'ERROR: Flutter not found at C:\flutter or %USERPROFILE%\flutter' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}
Write-Host "Flutter:  $flutterDir"
Write-Host ''

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

$envFile = 'S:\swimiq\.env'
if (-not (Test-Path $envFile)) {
    if (Test-Path 'S:\swimiq\.env.example') { Copy-Item 'S:\swimiq\.env.example' $envFile }
    Write-Host 'Created .env — paste Supabase keys, save, run again.' -ForegroundColor Yellow
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

if (-not $url -or -not $key -or $url -match 'your-project') {
    Write-Host 'ERROR: .env needs real SUPABASE_URL and SUPABASE_ANON_KEY' -ForegroundColor Red
    notepad $envFile
    Read-Host 'Press Enter'; exit 1
}

Write-Host 'Starting Chrome — wait 1-2 minutes...' -ForegroundColor Cyan
& $flutterBat pub get
if ($LASTEXITCODE -ne 0) { Read-Host 'Press Enter'; exit $LASTEXITCODE }

& $flutterBat run -d chrome --dart-define=SUPABASE_URL=$url --dart-define=SUPABASE_ANON_KEY=$key
Read-Host 'Press Enter to close'
exit $LASTEXITCODE
