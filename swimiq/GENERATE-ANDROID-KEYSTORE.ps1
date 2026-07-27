# One-time: create Google Play upload keystore + key.properties
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'scripts\swimiq-windows-paths.ps1')

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Generate Android Keystore' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot (Join-Path $PSScriptRoot 'scripts')
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

$keystoreDir = Join-Path $paths.WorkDir 'android\keystore'
$keystoreFile = Join-Path $keystoreDir 'swimiq-upload.jks'
$keyProps = Join-Path $paths.WorkDir 'android\key.properties'

New-Item -ItemType Directory -Force -Path $keystoreDir | Out-Null

if (Test-Path -LiteralPath $keystoreFile) {
    Write-Host "Keystore already exists:`n  $keystoreFile" -ForegroundColor Yellow
    Write-Host 'Keep this file. Do NOT create a second one for the same Play listing.' -ForegroundColor Yellow
    if (-not (Test-Path -LiteralPath $keyProps)) {
        Write-Host 'key.properties is missing — you still need passwords filled in.' -ForegroundColor Yellow
    }
    Read-Host 'Press Enter'; exit 0
}

$keytoolCmd = $null
$candidates = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
    "${env:ProgramFiles(x86)}\Android\Android Studio\jbr\bin\keytool.exe",
    "$env:LOCALAPPDATA\Programs\Android\Android Studio\jbr\bin\keytool.exe"
)
foreach ($c in $candidates) {
    if ($c -and (Test-Path -LiteralPath $c)) { $keytoolCmd = $c; break }
}
if (-not $keytoolCmd) {
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { $keytoolCmd = $cmd.Source }
}
if (-not $keytoolCmd) {
    Write-Host 'ERROR: keytool not found. Install Android Studio first.' -ForegroundColor Red
    Write-Host 'https://developer.android.com/studio' -ForegroundColor Yellow
    Read-Host 'Press Enter'; exit 1
}

Write-Host "Using keytool: $keytoolCmd" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Create a strong password (write it in 1Password / USB backup).' -ForegroundColor Yellow
Write-Host 'You will enter it twice for the keystore, then we save key.properties.' -ForegroundColor Yellow
Write-Host ''

$secure1 = Read-Host 'Store/key password' -AsSecureString
$secure2 = Read-Host 'Confirm password' -AsSecureString
$bstr1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure1)
$bstr2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure2)
try {
    $pass1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr1)
    $pass2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr2)
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)
}
if ([string]::IsNullOrWhiteSpace($pass1) -or $pass1 -ne $pass2) {
    Write-Host 'ERROR: Passwords empty or do not match.' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}
if ($pass1.Length -lt 6) {
    Write-Host 'ERROR: Password must be at least 6 characters (keytool requirement).' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

& $keytoolCmd -genkeypair -v `
    -keystore $keystoreFile `
    -storepass $pass1 `
    -keypass $pass1 `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -alias swimiq `
    -dname 'CN=SwimIQ, OU=Mobile, O=SwimIQ LLC, L=Groveport, ST=OH, C=US'

if ($LASTEXITCODE -ne 0) {
    Write-Host 'keytool failed.' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

@(
    "storePassword=$pass1"
    "keyPassword=$pass1"
    'keyAlias=swimiq'
    'storeFile=../keystore/swimiq-upload.jks'
) | Set-Content -LiteralPath $keyProps -Encoding ASCII

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host ' KEYSTORE READY' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host " Keystore: $keystoreFile" -ForegroundColor Green
Write-Host " Props:    $keyProps" -ForegroundColor Green
Write-Host ''
Write-Host 'BACK UP the .jks file + password NOW (USB + password manager).' -ForegroundColor Yellow
Write-Host 'If you lose them, you cannot update the same Play app forever.' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Next: fix .env with real Supabase keys, then PLAY-LAUNCH-NOW.bat' -ForegroundColor Cyan
Read-Host 'Press Enter'
