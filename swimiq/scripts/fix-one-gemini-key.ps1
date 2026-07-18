# Keep exactly ONE GEMINI_API_KEY line in swimiq\.env (the last real key wins).
$ErrorActionPreference = 'Stop'
$SwimIqDir = Split-Path $PSScriptRoot -Parent
$EnvFile = Join-Path $SwimIqDir '.env'

if (-not (Test-Path -LiteralPath $EnvFile)) {
    Write-Host "[FAIL] Missing $EnvFile" -ForegroundColor Red
    exit 1
}

$lines = Get-Content -LiteralPath $EnvFile
$geminiLines = @()
$other = New-Object System.Collections.Generic.List[string]
foreach ($line in $lines) {
    if ($line -match '^\s*GEMINI_API_KEY\s*=') {
        $geminiLines += $line
    } else {
        $other.Add($line) | Out-Null
    }
}

if ($geminiLines.Count -eq 0) {
    Write-Host '[WARN] No GEMINI_API_KEY line found.' -ForegroundColor Yellow
    Write-Host 'Add ONE line like: GEMINI_API_KEY=your_key_here' -ForegroundColor Yellow
    exit 2
}

function Get-KeyValue([string]$line) {
    $v = ($line -replace '^\s*GEMINI_API_KEY\s*=\s*', '').Trim().Trim('"').Trim("'")
    if ($v -notmatch '^\s*["'']' -and $v.Contains('#')) {
        $v = ($v -split '#', 2)[0].Trim()
    }
    return $v
}

$chosenLine = $null
$chosenVal = ''
foreach ($gl in $geminiLines) {
    $v = Get-KeyValue $gl
    if (-not [string]::IsNullOrWhiteSpace($v) -and $v.Length -ge 20) {
        $chosenLine = "GEMINI_API_KEY=$v"
        $chosenVal = $v
    }
}

if (-not $chosenLine) {
    Write-Host '[FAIL] GEMINI_API_KEY lines were empty/placeholder.' -ForegroundColor Red
    exit 3
}

if ($geminiLines.Count -gt 1) {
    Write-Host "[FIX] Found $($geminiLines.Count) GEMINI_API_KEY lines. Keeping only ONE." -ForegroundColor Yellow
} else {
    Write-Host '[OK] Exactly one GEMINI_API_KEY line.' -ForegroundColor Green
}

$out = New-Object System.Collections.Generic.List[string]
foreach ($o in $other) { $out.Add($o) | Out-Null }
$out.Add($chosenLine) | Out-Null
Set-Content -LiteralPath $EnvFile -Value $out.ToArray() -Encoding ascii

$prefix = if ($chosenVal.StartsWith('AQ.')) { 'AQ.' } elseif ($chosenVal.StartsWith('AIza')) { 'AIza' } else { 'key' }
Write-Host "[OK] Kept one key ($prefix… length $($chosenVal.Length))" -ForegroundColor Green
Write-Host "     File: $EnvFile" -ForegroundColor Green
Write-Host 'Next: close Elite windows, run START-SWIMIQ-WITH-ELITE.bat, analyze again.' -ForegroundColor Cyan
exit 0
