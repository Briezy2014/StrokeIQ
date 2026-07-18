# Shared Windows path helpers for Kara Williams (spaces + OneDrive + hooks)

function Get-SubstMapping {
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

function Get-PhysicalRootPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }

    $normalized = $Path.TrimEnd('\')
    if ($normalized -match '^([A-Z]):\\?(.*)$') {
        $letter = $matches[1]
        $rest = $matches[2]
        $subst = Get-SubstMapping
        if ($subst.ContainsKey($letter)) {
            if ([string]::IsNullOrEmpty($rest)) { return $subst[$letter].TrimEnd('\') }
            return (Join-Path $subst[$letter] $rest)
        }
    }

    try {
        return (Get-Item -LiteralPath $normalized -ErrorAction Stop).FullName.TrimEnd('\')
    } catch {
        return $normalized
    }
}

function Ensure-DirectoryJunction {
    param(
        [string]$LinkPath,
        [string]$TargetPath
    )

    $link = $LinkPath.TrimEnd('\')
    $target = (Get-PhysicalRootPath $TargetPath).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $target)) {
        throw "Target folder not found for junction ${link}:`n$target"
    }

    if (Test-Path -LiteralPath $link) {
        $item = Get-Item -LiteralPath $link -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $existing = $item.Target
            if ($existing -is [array]) { $existing = $existing[0] }
            if ($existing -and ($existing.TrimEnd('\') -ieq $target)) {
                Write-Host "OK  Junction $link -> $target" -ForegroundColor Green
                return $link
            }
            cmd /c "rmdir `"$link`"" | Out-Null
        } else {
            $children = @(Get-ChildItem -LiteralPath $link -Force -ErrorAction SilentlyContinue)
            if ($children.Count -eq 0) {
                Remove-Item -LiteralPath $link -Force
                Write-Host "OK  Removed empty folder blocking junction: $link" -ForegroundColor Yellow
            } else {
                throw "Cannot create junction - folder exists and is not a link:`n$link`nDelete or rename it, then run FIX-KARA-PATHS.bat again."
            }
        }
    }

    $parent = Split-Path -Parent $link
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    cmd /c "mklink /J `"$link`" `"$target`"" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "mklink failed for $link -> $target"
    }
    Write-Host "OK  Created junction $link -> $target" -ForegroundColor Green
    return $link
}

function Ensure-SubstDrive {
    param(
        [string]$Letter,
        [string]$TargetPath
    )

    $target = (Get-PhysicalRootPath $TargetPath).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $target)) {
        throw "Path does not exist for ${Letter}: drive: $target"
    }

    $subst = Get-SubstMapping
    $current = $null
    if ($subst.ContainsKey($Letter)) {
        $current = $subst[$Letter]
    }

    if ($current -and ($current.TrimEnd('\') -ieq $target)) {
        Write-Host "OK  ${Letter}: already mapped to $target" -ForegroundColor Green
        return "${Letter}:\"
    }

    Set-Location C:\
    if ($current) {
        cmd /c "subst ${Letter}: /D" | Out-Null
    }

    $quoted = $target -replace '"', '""'
    cmd /c "subst ${Letter}: `"$quoted`"" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "subst ${Letter}: failed for $target"
    }

    Write-Host "OK  Mapped ${Letter}: -> $target" -ForegroundColor Green
    return "${Letter}:\"
}

function Find-FlutterRoot {
    foreach ($candidate in @(
            'C:\FlutterWork',
            "$env:USERPROFILE\Flutter",
            "$env:USERPROFILE\flutter",
            'C:\flutter',
            'C:\src\flutter',
            'C:\Users\Kara Williams\Flutter',
            'C:\Users\Kara Williams\flutter'
        )) {
        $physical = Get-PhysicalRootPath $candidate
        if (Test-Path -LiteralPath "$physical\bin\flutter.bat") {
            return $physical
        }
    }

    $cmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        $bin = Split-Path -Parent $cmd.Source
        $root = (Get-PhysicalRootPath (Join-Path $bin '..')).TrimEnd('\')
        if (Test-Path -LiteralPath "$root\bin\flutter.bat") {
            return $root
        }
    }

    return $null
}

function Clear-SwimIqDartTool {
    param([string]$WorkDir)

    foreach ($name in @('.dart_tool', 'build')) {
        $dir = Join-Path $WorkDir $name
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        try {
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction Stop
            Write-Host "OK  Removed $dir" -ForegroundColor Yellow
        } catch {
            Write-Host "WARN Skipped locked folder (OK): $dir" -ForegroundColor Yellow
            Write-Host '      Close VS Code before launch if Chrome fails later.' -ForegroundColor DarkYellow
        }
    }
}

function Invoke-FlutterCleanSafe {
    param([string]$FlutterBat)

    $oldPref = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $FlutterBat clean 2>&1 | Out-Null
    } catch {
        Write-Host 'WARN flutter clean skipped (folder locked).' -ForegroundColor Yellow
    } finally {
        $ErrorActionPreference = $oldPref
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'WARN flutter clean had warnings (continuing anyway).' -ForegroundColor Yellow
    }
}

function Initialize-SwimIqWindowsPaths {
    param(
        [string]$ScriptsRoot,
        [switch]$CleanDartTool
    )

    Set-Location C:\

    $projectRoot = Get-PhysicalRootPath (Split-Path -Parent $ScriptsRoot)
    $strokeRoot = Get-PhysicalRootPath (Split-Path -Parent $projectRoot)

    Write-Host "Physical SwimIQ:  $projectRoot"
    Write-Host "Physical StrokeIQ: $strokeRoot"
    Write-Host ''

    $strokeLink = Ensure-DirectoryJunction -LinkPath 'C:\SwimIQWork' -TargetPath $strokeRoot
    # StrokeIQ root + \swimiq. If junction was wrongly pointed at swimiq already, don't nest.
    if ((Split-Path -Leaf $strokeRoot) -ieq 'swimiq') {
        $workDir = $strokeLink
    } else {
        $workDir = Join-Path $strokeLink 'swimiq'
    }
    $workDir = (Get-PhysicalRootPath $workDir).TrimEnd('\')

    $flutterRootPhysical = Find-FlutterRoot
    if (-not $flutterRootPhysical) {
        throw 'Flutter not found. Install to C:\flutter or C:\Users\Kara Williams\flutter'
    }
    Write-Host "Physical Flutter: $flutterRootPhysical"

    $flutterRoot = $flutterRootPhysical
    $flutterBat = Join-Path $flutterRoot 'bin\flutter.bat'

    if ($flutterRootPhysical -match ' ') {
        $flutterRoot = Ensure-DirectoryJunction -LinkPath 'C:\FlutterWork' -TargetPath $flutterRootPhysical
        $flutterBat = Join-Path $flutterRoot 'bin\flutter.bat'
    }

    $pubCache = 'C:\SwimIQPub'
    New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
    $env:PUB_CACHE = $pubCache
    [Environment]::SetEnvironmentVariable('PUB_CACHE', $pubCache, 'User')
    [Environment]::SetEnvironmentVariable('PUB_CACHE', $pubCache, 'Process')
    $env:FLUTTER_ROOT = $flutterRoot
    $env:Path = "$(Split-Path $flutterBat -Parent);$env:Path"

    if (-not (Test-Path -LiteralPath $flutterBat)) {
        throw "Flutter not found at $flutterBat"
    }
    if (-not (Test-Path -LiteralPath $workDir)) {
        throw "SwimIQ folder not found at $workDir"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $workDir 'pubspec.yaml'))) {
        throw "SwimIQ folder looks wrong (no pubspec.yaml): $workDir"
    }

    if ($CleanDartTool) {
        Clear-SwimIqDartTool -WorkDir $workDir
    }

    Set-Location -LiteralPath $workDir

    Write-Host "OK  Working folder: $workDir" -ForegroundColor Green
    Write-Host "OK  PUB_CACHE: $pubCache" -ForegroundColor Green
    Write-Host "OK  Flutter: $flutterBat" -ForegroundColor Green
    Write-Host ''

    return [PSCustomObject]@{
        FlutterBat = $flutterBat
        WorkDir    = $workDir
        PubCache   = $pubCache
    }
}
