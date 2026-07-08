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
            throw "Cannot create junction — folder already exists and is not a link:`n$link"
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
            "$env:USERPROFILE\flutter",
            'C:\flutter',
            'C:\src\flutter'
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

    $dartTool = Join-Path $WorkDir '.dart_tool'
    $buildDir = Join-Path $WorkDir 'build'
    foreach ($dir in @($dartTool, $buildDir)) {
        if (Test-Path -LiteralPath $dir) {
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "OK  Removed $dir" -ForegroundColor Yellow
        }
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
    $workDir = Join-Path $strokeLink 'swimiq'

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
