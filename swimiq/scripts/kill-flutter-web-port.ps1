# Free Flutter web ports so launch does not die with errno 10048.
$ErrorActionPreference = 'SilentlyContinue'
$ports = @(7357, 7358, 7359, 7360, 64866)

function Stop-ListenersOnPort([int]$port) {
    $killed = @()
    try {
        $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conns) {
            $procId = $c.OwningProcess
            if ($procId -and $procId -gt 0) {
                Write-Host ("Stopping old process on port {0} (PID {1})..." -f $port, $procId) -ForegroundColor Yellow
                Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                $killed += $procId
            }
        }
    } catch {}

    $lines = netstat -ano | Select-String (":{0}\s+.*LISTENING" -f $port)
    foreach ($line in $lines) {
        $parts = ($line.ToString() -split '\s+') | Where-Object { $_ -ne '' }
        $procId = $parts[-1]
        if ($procId -match '^\d+$' -and [int]$procId -gt 0) {
            Write-Host ("Stopping old process on port {0} (PID {1})..." -f $port, $procId) -ForegroundColor Yellow
            Stop-Process -Id ([int]$procId) -Force -ErrorAction SilentlyContinue
            $killed += [int]$procId
        }
    }
    return ($killed.Count -gt 0)
}

$any = $false
foreach ($p in $ports) {
    if (Stop-ListenersOnPort $p) { $any = $true }
}

# Also stop stale dart/flutter web runner leftovers when safe.
try {
    Get-Process -Name 'dart','flutter' -ErrorAction SilentlyContinue | ForEach-Object {
        $cmd = ''
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter ("ProcessId={0}" -f $_.Id)).CommandLine
        } catch {}
        if ($cmd -and ($cmd -match 'webdev|resident_web|flutter_tools.*run|chrome')) {
            Write-Host ("Stopping stale Flutter helper PID {0}..." -f $_.Id) -ForegroundColor Yellow
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            $any = $true
        }
    }
} catch {}

Start-Sleep -Seconds 1
if ($any) {
    Write-Host '[OK] Cleared old Flutter web ports.' -ForegroundColor Green
} else {
    Write-Host '[OK] Flutter web ports were free.' -ForegroundColor Green
}
exit 0
