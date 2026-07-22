# Find the real SwimIQ folder on this Windows PC.
# Never assume Desktop\StrokeIQ — that path is often missing (OneDrive / renamed folders).

$ErrorActionPreference = 'SilentlyContinue'

Write-Host ''
Write-Host 'Looking for swimiq\pubspec.yaml ...' -ForegroundColor Cyan

$roots = New-Object System.Collections.Generic.List[string]
foreach ($p in @(
    $env:USERPROFILE,
    (Join-Path $env:USERPROFILE 'Desktop'),
    (Join-Path $env:USERPROFILE 'Documents'),
    (Join-Path $env:USERPROFILE 'Downloads'),
    $env:OneDrive,
    $env:OneDriveConsumer,
    $env:OneDriveCommercial,
    'C:\',
    'D:\',
    'S:\'
)) {
    if ($p -and (Test-Path -LiteralPath $p)) { [void]$roots.Add($p) }
}

# Extra OneDrive / school account folders under the user profile
Get-ChildItem -LiteralPath $env:USERPROFILE -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'OneDrive*' } |
    ForEach-Object { [void]$roots.Add($_.FullName) }

$hits = @()
foreach ($root in ($roots | Select-Object -Unique)) {
    Write-Host ("  scanning: " + $root)
    $found = Get-ChildItem -LiteralPath $root -Filter 'pubspec.yaml' -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -match '[\\/]swimiq[\\/]pubspec\.yaml$' -and
            (Test-Path -LiteralPath (Join-Path $_.Directory.FullName 'lib'))
        } |
        Select-Object -ExpandProperty DirectoryName
    if ($found) { $hits += @($found) }
}

$hits = $hits | Select-Object -Unique
if (-not $hits -or $hits.Count -eq 0) {
    Write-Host ''
    Write-Host 'NOT FOUND.' -ForegroundColor Red
    Write-Host 'Open File Explorer -> This PC -> search for: pubspec.yaml'
    Write-Host 'Use the result inside a folder named swimiq.'
    exit 1
}

Write-Host ''
Write-Host 'FOUND SwimIQ here:' -ForegroundColor Green
$i = 1
foreach ($h in $hits) {
    Write-Host ("  [$i] $h")
    $i++
}

$choice = $hits[0]
$repoRoot = Split-Path -Parent $choice

Write-Host ''
Write-Host 'Using first match:' -ForegroundColor Green
Write-Host ("  swimiq folder: $choice")
Write-Host ("  repo folder:   $repoRoot")

# Map S: for shorter paths when possible
try {
    if (-not (Test-Path -LiteralPath 'S:\')) {
        subst S: "$repoRoot" | Out-Null
        Write-Host 'Mapped S: -> repo folder' -ForegroundColor Yellow
    } else {
        Write-Host 'S: already mapped' -ForegroundColor Yellow
    }
} catch {
    Write-Host 'Could not map S: (optional)' -ForegroundColor DarkYellow
}

Write-Host ''
Write-Host 'Next commands (copy/paste):' -ForegroundColor Cyan
Write-Host "  cd `"$choice`""
Write-Host '  git checkout main'
Write-Host '  git pull origin main'
Write-Host '  dir START-SWIMIQ.bat'
Write-Host ''
Write-Host 'Opening File Explorer...'
Start-Process explorer.exe $choice

Set-Clipboard -Value $choice -ErrorAction SilentlyContinue
Write-Host 'Path copied to clipboard (if allowed).'
exit 0
