# Keep exactly ONE GEMINI_API_KEY line in swimiq\.env (the last real key wins).
# Never throws hard - always exit 0/2/3 with a clear message.
$ErrorActionPreference = 'Continue'
$SwimIqDir = Split-Path $PSScriptRoot -Parent
$EnvFile = Join-Path $SwimIqDir '.env'

if (-not (Test-Path -LiteralPath $EnvFile)) {
    Write-Host "[WARN] Missing $EnvFile" -ForegroundColor Yellow
    exit 0
}

try {
    $lines = Get-Content -LiteralPath $EnvFile -ErrorAction Stop
} catch {
    Write-Host "[WARN] Could not read .env: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 0
}

$geminiLines = @()
$other = New-Object System.Collections.Generic.List[string]
foreach ($line in $lines) {
    if ($line -match '^\s*GEMINI_API_KEY\s*=') {
        $geminiLines += $line
    } else {
        [void]$other.Add($line)
    }
}

if ($geminiLines.Count -eq 0) {
    Write-Host '[WARN] No GEMINI_API_KEY line found (coaching may use local tips only).' -ForegroundColor Yellow
    exit 0
}

function Get-KeyValue([string]$line) {
    $v = ($line -replace '^\s*GEMINI_API_KEY\s*=\s*', '').Trim().Trim('"').Trim("'")
    if ($v.Contains('#')) { $v = ($v -split '#', 2)[0].Trim() }
    return $v
}

$chosenVal = ''
foreach ($gl in $geminiLines) {
    $v = Get-KeyValue $gl
    if (-not [string]::IsNullOrWhiteSpace($v) -and $v.Length -ge 20) {
        $chosenVal = $v
    }
}

if ([string]::IsNullOrWhiteSpace($chosenVal)) {
    Write-Host '[WARN] GEMINI_API_KEY lines were empty/placeholder.' -ForegroundColor Yellow
    exit 0
}

if ($geminiLines.Count -gt 1) {
    Write-Host "[FIX] Found $($geminiLines.Count) GEMINI_API_KEY lines. Keeping ONLY the last one." -ForegroundColor Yellow
    [void]$other.Add("GEMINI_API_KEY=$chosenVal")
    try {
        Set-Content -LiteralPath $EnvFile -Value $other.ToArray() -Encoding ascii
        Write-Host '[OK] .env cleaned to one GEMINI_API_KEY line.' -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Could not rewrite .env: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host 'Delete the extra GEMINI_API_KEY line in Notepad yourself.' -ForegroundColor Yellow
    }
} else {
    Write-Host '[OK] Exactly one GEMINI_API_KEY line.' -ForegroundColor Green
}
exit 0
