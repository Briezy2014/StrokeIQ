# Stop whatever is listening on port 8080 so a fresh Elite server can start.
# ASCII-only.
$ErrorActionPreference = 'SilentlyContinue'
$killed = $false

function Test-Port8080InUse {
    try {
        $conns = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
        if ($conns) { return $true }
    } catch {}
    $lines = netstat -ano | Select-String ':8080\s+.*LISTENING'
    return ($null -ne $lines -and @($lines).Count -gt 0)
}

function Stop-ListenersOn8080 {
    $stopped = $false
    try {
        $conns = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conns) {
            $procId = $c.OwningProcess
            if ($procId -and $procId -gt 0) {
                Write-Host "Stopping old process on port 8080 (PID $procId)..." -ForegroundColor Yellow
                Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                $stopped = $true
            }
        }
    } catch {}

    $lines = netstat -ano | Select-String ':8080\s+.*LISTENING'
    foreach ($line in $lines) {
        $parts = ($line.ToString() -split '\s+') | Where-Object { $_ -ne '' }
        $procId = $parts[-1]
        if ($procId -match '^\d+$' -and [int]$procId -gt 0) {
            Write-Host "Stopping old process on port 8080 (PID $procId)..." -ForegroundColor Yellow
            Stop-Process -Id ([int]$procId) -Force -ErrorAction SilentlyContinue
            $stopped = $true
        }
    }
    return $stopped
}

$killed = Stop-ListenersOn8080
Start-Sleep -Seconds 1
if (Test-Port8080InUse) {
    # One more try
    $killed = (Stop-ListenersOn8080) -or $killed
    Start-Sleep -Seconds 1
}

if (Test-Port8080InUse) {
    Write-Host '[FAIL] Port 8080 is still in use after kill attempts.' -ForegroundColor Red
    Write-Host 'Close any other Elite Video Lab window, then run START-SWIMIQ-WITH-ELITE.bat again.' -ForegroundColor Yellow
    exit 1
}

if ($killed) {
    Write-Host '[OK] Cleared port 8080 for a fresh Elite server.' -ForegroundColor Green
} else {
    Write-Host '[OK] Port 8080 was free.' -ForegroundColor Green
}
exit 0
