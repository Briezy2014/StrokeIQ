# Stop whatever is listening on port 8080 so a fresh Elite server can start.
$ErrorActionPreference = 'SilentlyContinue'
$killed = $false
try {
    $conns = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
    foreach ($c in $conns) {
        $procId = $c.OwningProcess
        if ($procId -and $procId -gt 0) {
            Write-Host "Stopping old process on port 8080 (PID $procId)..." -ForegroundColor Yellow
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
            $killed = $true
        }
    }
} catch {}

if (-not $killed) {
    $lines = netstat -ano | Select-String ':8080\s+.*LISTENING'
    foreach ($line in $lines) {
        $parts = ($line.ToString() -split '\s+') | Where-Object { $_ -ne '' }
        $procId = $parts[-1]
        if ($procId -match '^\d+$' -and [int]$procId -gt 0) {
            Write-Host "Stopping old process on port 8080 (PID $procId)..." -ForegroundColor Yellow
            Stop-Process -Id ([int]$procId) -Force -ErrorAction SilentlyContinue
            $killed = $true
        }
    }
}

Start-Sleep -Seconds 1
if ($killed) {
    Write-Host '[OK] Cleared port 8080 for a fresh Elite server.' -ForegroundColor Green
} else {
    Write-Host '[OK] Port 8080 was free.' -ForegroundColor Green
}
exit 0
