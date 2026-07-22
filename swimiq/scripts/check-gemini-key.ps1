# Exit 0 if swimiq\.env has a real GEMINI_API_KEY (AIza..., AQ...., or other long key).
$ErrorActionPreference = 'Stop'
$SwimIqDir = Split-Path $PSScriptRoot -Parent
$EnvFile = Join-Path $SwimIqDir '.env'
if (-not (Test-Path -LiteralPath $EnvFile)) { exit 1 }
$line = Get-Content -LiteralPath $EnvFile |
    Where-Object { $_ -match '^\s*GEMINI_API_KEY\s*=' } |
    Select-Object -First 1
if (-not $line) { exit 1 }
$v = ($line -replace '^\s*GEMINI_API_KEY\s*=\s*', '').Trim().Trim('"').Trim("'")
if ([string]::IsNullOrWhiteSpace($v)) { exit 1 }
foreach ($b in @('paste_', 'your-', 'changeme', 'your_key', 'xxx')) {
    if ($v.ToLowerInvariant().Contains($b)) { exit 1 }
}
if ($v.Length -lt 20) { exit 1 }
exit 0
