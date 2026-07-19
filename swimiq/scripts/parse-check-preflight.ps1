# ASCII-only. Validates final-try-preflight.ps1 parses on Windows PowerShell 5.1.
$ErrorActionPreference = 'Stop'
$target = Join-Path $PSScriptRoot 'final-try-preflight.ps1'
if (-not (Test-Path -LiteralPath $target)) {
    Write-Host ("[FAIL] Missing {0}" -f $target) -ForegroundColor Red
    exit 1
}
$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($target, [ref]$tokens, [ref]$errors)
if ($errors -and $errors.Count -gt 0) {
    Write-Host '[FAIL] Preflight script syntax error:' -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host $err.ToString() -ForegroundColor Red
    }
    exit 1
}
Write-Host '[OK] Preflight script syntax is valid' -ForegroundColor Green
exit 0
