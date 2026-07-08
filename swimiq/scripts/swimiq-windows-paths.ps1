# Shared Windows path helpers for Kara Williams (spaces + subst drives)

function Get-SubstMapping {
    $map = @{}
    $lines = cmd /c subst 2>$null
    foreach ($line in $lines) {
        if ($line -match '^([A-Z]):\:\\?\s+=>\s+(.+)$') {
            $map[$matches[1]] = $matches[2].Trim()
        }
    }
    return $map
}

function Get-PhysicalRootPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }

    $normalized = $Path.TrimEnd('\')
    if ($normalized -match '^[A-Z]:$') {
        $letter = $normalized[0]
        $subst = Get-SubstMapping
        if ($subst.ContainsKey($letter)) {
            return $subst[$letter]
        }
    }

    try {
        return (Get-Item -LiteralPath $normalized -ErrorAction Stop).FullName
    } catch {
        return $normalized
    }
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
        $root = $bin.TrimEnd('\bin').TrimEnd('\')
        $physical = Get-PhysicalRootPath $root
        if (Test-Path -LiteralPath "$physical\bin\flutter.bat") {
            return $physical
        }
    }

    return $null
}

function Initialize-SwimIqWindowsPaths {
    param(
        [string]$ScriptsRoot
    )

    $projectRoot = Get-PhysicalRootPath (Split-Path -Parent $ScriptsRoot)
    $strokeRoot = Get-PhysicalRootPath (Split-Path -Parent $projectRoot)

    Write-Host "Physical SwimIQ: $projectRoot"
    Write-Host "Physical StrokeIQ: $strokeRoot"
    Write-Host ''

    $flutterRoot = Find-FlutterRoot
    if (-not $flutterRoot) {
        throw 'Flutter not found. Install to C:\flutter or C:\Users\Kara Williams\flutter'
    }
    Write-Host "Physical Flutter: $flutterRoot"

    $needsMapping = ($flutterRoot -match ' ') -or ($strokeRoot -match ' ') -or ($projectRoot -match ' ')
    $flutterBat = Join-Path $flutterRoot 'bin\flutter.bat'
    $workDir = $projectRoot

    if ($needsMapping) {
        Ensure-SubstDrive -Letter 'S' -TargetPath $strokeRoot | Out-Null
        if ($flutterRoot -match ' ') {
            Ensure-SubstDrive -Letter 'F' -TargetPath $flutterRoot | Out-Null
            $flutterBat = 'F:\bin\flutter.bat'
        }
        $workDir = 'S:\swimiq'
    }

    $pubCache = 'S:\pub-cache'
    New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
    $env:PUB_CACHE = $pubCache
    [Environment]::SetEnvironmentVariable('PUB_CACHE', $pubCache, 'User')

    if ($flutterBat -eq 'F:\bin\flutter.bat') {
        $env:Path = "F:\bin;$env:Path"
    } else {
        $flutterBin = Split-Path -Parent $flutterBat
        $env:Path = "$flutterBin;$env:Path"
    }

    if (-not (Test-Path -LiteralPath $flutterBat)) {
        throw "Flutter not found at $flutterBat"
    }
    if (-not (Test-Path -LiteralPath $workDir)) {
        throw "SwimIQ folder not found at $workDir"
    }

    Set-Location -LiteralPath $workDir

    return [PSCustomObject]@{
        FlutterBat = $flutterBat
        WorkDir    = $workDir
        PubCache   = $pubCache
    }
}
