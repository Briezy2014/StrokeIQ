# Exit 0 if Elite /health is up on 127.0.0.1:8080
try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8080/health' -TimeoutSec 2
    if ($r.StatusCode -eq 200 -and $r.Content -match 'engine_version') {
        exit 0
    }
} catch {}
exit 1
