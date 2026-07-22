# Create SwimIQ Play upload keystore (finds keytool from Android Studio Java)
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Find-Keytool {
    $candidates = @(
        "$env:JAVA_HOME\bin\keytool.exe",
        "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
        "${env:ProgramFiles(x86)}\Android\Android Studio\jbr\bin\keytool.exe",
        "$env:LOCALAPPDATA\Programs\Android\Android Studio\jbr\bin\keytool.exe",
        "C:\Program Files\Java\*\bin\keytool.exe",
        "C:\Program Files\Eclipse Adoptium\*\bin\keytool.exe",
        "C:\Program Files\Microsoft\jdk-*\bin\keytool.exe"
    )

    foreach ($path in $candidates) {
        $resolved = @(Get-Item $path -ErrorAction SilentlyContinue)
        if ($resolved.Count -gt 0) {
            return $resolved[0].FullName
        }
    }

    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    return $null
}

$keytool = Find-Keytool
if (-not $keytool) {
    Write-Host ""
    Write-Host "ERROR: keytool not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Android Studio, then run this script again:" -ForegroundColor Yellow
    Write-Host "  https://developer.android.com/studio" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or run keytool manually (paste ONE line that exists on your PC):" -ForegroundColor Yellow
    Write-Host '  & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore android\keystores\swimiq-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias swimiq'
    exit 1
}

Write-Host "Using keytool: $keytool" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path (Join-Path $repoRoot "android\keystores") | Out-Null

& $keytool -genkey -v `
    -keystore (Join-Path $repoRoot "android\keystores\swimiq-upload-keystore.jks") `
    -keyalg RSA -keysize 2048 -validity 10000 -alias swimiq

if ($LASTEXITCODE -ne 0) {
    throw "keytool failed with exit code $LASTEXITCODE"
}

$example = Join-Path $repoRoot "android\key.properties.example"
$props = Join-Path $repoRoot "android\key.properties"
if (-not (Test-Path $props) -and (Test-Path $example)) {
    Copy-Item $example $props
    Write-Host ""
    Write-Host "Created android\key.properties — open it and paste your keystore passwords." -ForegroundColor Yellow
    notepad $props
}

Write-Host ""
Write-Host "Keystore created: android\keystores\swimiq-upload-keystore.jks" -ForegroundColor Green
Write-Host "Next: fill android\key.properties, then run scripts\build-android-release.ps1" -ForegroundColor Green
